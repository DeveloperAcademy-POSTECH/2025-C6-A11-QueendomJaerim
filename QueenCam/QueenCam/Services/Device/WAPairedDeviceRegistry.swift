//
//  WAPairedDeviceRegistry.swift
//  QueenCam
//
//  Created by 임영택 on 8/10/26.
//

import Foundation
import SwiftData
import WiFiAware

nonisolated final class WAPairedDeviceRegistry: WAPairedDeviceRegistryProtocol, @unchecked Sendable {
  let devices: AsyncStream<[ExtendedWAPairedDevice]>

  private let repository: DeviceRepositoryProtocol
  private let now: @Sendable () -> Date
  private let uuid: @Sendable () -> UUID
  private let upstreamTask: Task<Void, Never>
  private let logger: QueenLogger

  init(
    repository: DeviceRepositoryProtocol,
    deviceUpdates: @escaping @Sendable () -> AsyncThrowingStream<[UInt64: WAPairedDevice], any Error>,
    now: @escaping @Sendable () -> Date = Date.init,
    uuid: @escaping @Sendable () -> UUID = UUID.init
  ) {
    self.repository = repository
    self.now = now
    self.uuid = uuid
    let logger = QueenLogger(category: "WAPairedDeviceRegistry")
    self.logger = logger

    let (devices, continuation) = AsyncStream.makeStream(of: [ExtendedWAPairedDevice].self)
    self.devices = devices
    self.upstreamTask = Task {
      do {
        for try await updates in deviceUpdates() {
          var extendedDevices: [ExtendedWAPairedDevice] = []
          for device in updates.values {
            let extended = await Self.extend(
              device: device,
              repository: repository,
              now: now,
              uuid: uuid,
              logger: logger
            )
            extendedDevices.append(extended)
          }

          let sorted = extendedDevices.sorted(by: Self.isOrderedBefore)
          logger.debug("페어링 기기 목록 결합 완료 count=\(sorted.count)")
          continuation.yield(sorted)
        }
      } catch {
        logger.error("Wi-Fi Aware 페어링 기기 스트림 처리 실패: \(error)")
      }
      continuation.finish()
    }
  }

  convenience init(repository: DeviceRepositoryProtocol) {
    self.init(repository: repository) {
      AsyncThrowingStream { continuation in
        let task = Task {
          do {
            for try await devices in WAPairedDevice.allDevices {
              continuation.yield(devices)
            }
            continuation.finish()
          } catch {
            continuation.finish(throwing: error)
          }
        }
        continuation.onTermination = { _ in
          task.cancel()
        }
      }
    }
  }

  static func inMemory() -> WAPairedDeviceRegistry {
    do {
      let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try ModelContainer(for: StoredDevice.self, configurations: configuration)
      return WAPairedDeviceRegistry(repository: DeviceRepository(modelContainer: container))
    } catch {
      fatalError("인메모리 상대 기기 저장소 생성에 실패했습니다: \(error)")
    }
  }

  deinit {
    upstreamTask.cancel()
  }

  func recordConnection(to device: WAPairedDevice) async {
    do {
      let timestamp = now()
      let existing = try await repository.device(waDeviceId: device.id)
      let record: DeviceRecord
      if let existing {
        record = existing.merging(device: device, lastConnectedAt: timestamp)
      } else {
        record = DeviceRecord(
          id: uuid(),
          device: device,
          createdAt: timestamp,
          lastConnectedAt: timestamp
        )
      }
      try await repository.upsert(record)
      logger.debug(
        "상대 기기 최근 연결 시간 갱신 waDeviceId=\(device.id), id=\(record.id), lastConnectedAt=\(timestamp)"
      )
    } catch {
      logger.error("상대 기기 연결 기록 업서트 실패 waDeviceId=\(device.id): \(error)")
    }
  }

  private static func extend(
    device: WAPairedDevice,
    repository: DeviceRepositoryProtocol,
    now: @Sendable () -> Date,
    uuid: @Sendable () -> UUID,
    logger: QueenLogger
  ) async -> ExtendedWAPairedDevice {
    do {
      if let existing = try await repository.device(waDeviceId: device.id) {
        let updated = existing.merging(device: device)
        if updated.metadata != existing.metadata {
          do {
            try await repository.upsert(updated)
            logger.debug(
              "OS 메타데이터로 상대 기기 갱신 waDeviceId=\(device.id), id=\(existing.id), "
                + "old=\(existing.metadata), new=\(updated.metadata)"
            )
          } catch {
            logger.warning("상대 기기 메타데이터 저장 실패 waDeviceId=\(device.id), 다음 조회에서 재시도: \(error)")
          }
        }
        return ExtendedWAPairedDevice(device: device, record: updated, isNew: false)
      }

      let discoveredAt = now()
      let newRecord = DeviceRecord(
        id: uuid(),
        device: device,
        createdAt: discoveredAt,
        lastConnectedAt: nil
      )
      do {
        try await repository.upsert(newRecord)
        logger.debug(
          "새 상대 기기 발견 및 저장 waDeviceId=\(device.id), id=\(newRecord.id), createdAt=\(discoveredAt)"
        )
      } catch {
        logger.warning("새 상대 기기 저장 실패 waDeviceId=\(device.id), 다음 조회에서 재시도: \(error)")
      }
      return ExtendedWAPairedDevice(device: device, record: newRecord, isNew: true)
    } catch {
      let fallback = DeviceRecord(
        id: uuid(),
        device: device,
        createdAt: now(),
        lastConnectedAt: nil
      )
      logger.warning("상대 기기 조회 실패로 폴백 발행 waDeviceId=\(device.id): \(error)")
      do {
        try await repository.upsert(fallback)
      } catch {
        logger.error("폴백 상대 기기 업서트 실패 waDeviceId=\(device.id): \(error)")
      }
      return ExtendedWAPairedDevice(device: device, record: fallback, isNew: true)
    }
  }

  private static func isOrderedBefore(_ lhs: ExtendedWAPairedDevice, _ rhs: ExtendedWAPairedDevice) -> Bool {
    if lhs.isNew != rhs.isNew {
      return lhs.isNew
    }

    if !lhs.isNew, lhs.lastConnectedAt != rhs.lastConnectedAt {
      switch (lhs.lastConnectedAt, rhs.lastConnectedAt) {
      case (.some(let lhsDate), .some(let rhsDate)):
        return lhsDate > rhsDate
      case (.some, .none):
        return true
      case (.none, .some):
        return false
      case (.none, .none):
        break
      }
    }

    let lhsName = lhs.pairingName ?? lhs.name
    let rhsName = rhs.pairingName ?? rhs.name
    if lhsName != rhsName {
      return lhsName.localizedStandardCompare(rhsName) == .orderedAscending
    }
    return lhs.device.id < rhs.device.id
  }
}
