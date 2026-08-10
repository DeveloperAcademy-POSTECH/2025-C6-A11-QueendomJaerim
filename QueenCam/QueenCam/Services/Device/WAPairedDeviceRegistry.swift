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
  private let state: RegistryState
  private let continuation: AsyncStream<[ExtendedWAPairedDevice]>.Continuation

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
    let state = RegistryState()
    self.state = state

    let (devices, continuation) = AsyncStream.makeStream(of: [ExtendedWAPairedDevice].self)
    self.devices = devices
    self.continuation = continuation
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
          await state.replace(sorted)
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
      let record = try await repository.recordConnection(
        device: device,
        id: uuid(),
        connectedAt: timestamp
      )
      if let updated = await state.update(device: device, record: record) {
        continuation.yield(updated.sorted(by: Self.isOrderedBefore))
      }
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
      let discoveredAt = now()
      let (record, isNew) = try await repository.refresh(
        device: device,
        id: uuid(),
        discoveredAt: discoveredAt
      )
      logger.debug("상대 기기 원자 갱신 waDeviceId=\(device.id), id=\(record.id), isNew=\(isNew)")
      return ExtendedWAPairedDevice(device: device, record: record, isNew: isNew)
    } catch {
      let fallback = DeviceRecord(
        id: uuid(),
        device: device,
        createdAt: now(),
        lastConnectedAt: nil
      )
      logger.warning("상대 기기 조회 실패로 폴백 발행 waDeviceId=\(device.id): \(error)")
      do {
        _ = try await repository.refresh(device: device, id: fallback.id, discoveredAt: fallback.createdAt)
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

private actor RegistryState {
  private var devices: [UInt64: ExtendedWAPairedDevice] = [:]

  func replace(_ updated: [ExtendedWAPairedDevice]) {
    devices = Dictionary(uniqueKeysWithValues: updated.map { item in
      guard
        let current = devices[item.device.id],
        let currentDate = current.lastConnectedAt,
        currentDate > (item.lastConnectedAt ?? .distantPast)
      else {
        return (item.device.id, item)
      }
      let record = item.record.merging(device: item.device, lastConnectedAt: currentDate)
      return (item.device.id, ExtendedWAPairedDevice(device: item.device, record: record, isNew: false))
    })
  }

  func update(device: WAPairedDevice, record: DeviceRecord) -> [ExtendedWAPairedDevice]? {
    guard devices[device.id] != nil else { return nil }
    devices[device.id] = ExtendedWAPairedDevice(device: device, record: record, isNew: false)
    return Array(devices.values)
  }
}
