//
//  WAPairedDeviceRegistryTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 8/10/26.
//

import Foundation
import Testing
import WiFiAware

@testable import QueenCam

private enum DeviceRepositoryTestError: Error {
  case failed
}

private actor FakeDeviceRepository: DeviceRepositoryProtocol {
  private var records: [UInt64: DeviceRecord]
  private let shouldFail: Bool

  init(records: [DeviceRecord] = [], shouldFail: Bool = false) {
    self.records = Dictionary(uniqueKeysWithValues: records.map { ($0.waDeviceId, $0) })
    self.shouldFail = shouldFail
  }

  func device(waDeviceId: UInt64) throws -> DeviceRecord? {
    if shouldFail { throw DeviceRepositoryTestError.failed }
    return records[waDeviceId]
  }

  func upsert(_ record: DeviceRecord) throws -> DeviceRecord {
    if shouldFail { throw DeviceRepositoryTestError.failed }
    records[record.waDeviceId] = record
    return record
  }
}

@Suite("WAPairedDeviceRegistry Tests")
struct WAPairedDeviceRegistryTests {
  @Test("처음 발견한 기기는 신규로 발행하고 즉시 저장한다")
  func firstDiscoveryIsNewAndPersists() async throws {
    let repository = FakeDeviceRepository()
    let (stream, continuation) = makeDeviceStream()
    let registry = makeRegistry(repository: repository, stream: stream)
    var iterator = registry.devices.makeAsyncIterator()
    let device = makeDevice(id: 1001, name: "작가 폰", pairingName: "작가")

    continuation.yield([device.id: device])
    let devices = try #require(await iterator.next())

    #expect(devices.count == 1)
    #expect(devices[0].isNew)
    #expect(devices[0].device.id == 1001)
    let saved = try #require(try await repository.device(waDeviceId: 1001))
    #expect(saved.createdAt == Date(timeIntervalSince1970: 1_000))
    #expect(saved.id == UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
  }

  @Test("다시 발견한 기기는 기존 기기로 발행하고 OS 메타데이터를 저장한다")
  func repeatDiscoveryRefreshesMetadata() async throws {
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
    let createdAt = Date(timeIntervalSince1970: 10)
    let lastConnectedAt = Date(timeIntervalSince1970: 20)
    let repository = FakeDeviceRepository(records: [
      DeviceRecord(
        id: id,
        waDeviceId: 1010,
        name: "이전 이름",
        pairingName: "이전 페어링 이름",
        vendorName: "이전 제조사",
        modelName: "이전 모델",
        createdAt: createdAt,
        lastConnectedAt: lastConnectedAt
      )
    ])
    let (stream, continuation) = makeDeviceStream()
    let registry = makeRegistry(repository: repository, stream: stream)
    var iterator = registry.devices.makeAsyncIterator()
    let current = makeDevice(
      id: 1010,
      name: "현재 이름",
      pairingName: "현재 페어링 이름",
      vendorName: "Apple",
      modelName: "iPhone 17 Pro"
    )

    continuation.yield([current.id: current])
    let devices = try #require(await iterator.next())

    #expect(devices[0].isNew == false)
    #expect(devices[0].id == id)
    let saved = try #require(try await repository.device(waDeviceId: 1010))
    #expect(saved.name == "현재 이름")
    #expect(saved.pairingName == "현재 페어링 이름")
    #expect(saved.vendorName == "Apple")
    #expect(saved.modelName == "iPhone 17 Pro")
    #expect(saved.id == id)
    #expect(saved.createdAt == createdAt)
    #expect(saved.lastConnectedAt == lastConnectedAt)
  }

  @Test("신규 기기를 먼저, 기존 기기는 최근 연결 순서로 정렬한다")
  func sortsNewAndRecentlyConnectedFirst() async throws {
    let repository = FakeDeviceRepository(records: [
      makeRecord(waDeviceId: 2001, pairingName: "오래된", lastConnectedAt: Date(timeIntervalSince1970: 100)),
      makeRecord(waDeviceId: 2002, pairingName: "최근", lastConnectedAt: Date(timeIntervalSince1970: 300)),
      makeRecord(waDeviceId: 2003, pairingName: "미연결", lastConnectedAt: nil)
    ])
    let (stream, continuation) = makeDeviceStream()
    let registry = makeRegistry(repository: repository, stream: stream)
    var iterator = registry.devices.makeAsyncIterator()
    let devices = [
      makeDevice(id: 2001, name: "오래된", pairingName: "오래된"),
      makeDevice(id: 2002, name: "최근", pairingName: "최근"),
      makeDevice(id: 2003, name: "미연결", pairingName: "미연결"),
      makeDevice(id: 2004, name: "신규", pairingName: "신규")
    ]

    continuation.yield(Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) }))
    let sorted = try #require(await iterator.next())

    #expect(sorted.map(\.device.id) == [2004, 2002, 2001, 2003])
  }

  @Test("연결 완료 시 저장 기록이 없어도 생성하고 최근 연결 시간을 기록한다")
  func recordsConnectionWithFallbackUpsert() async throws {
    let repository = FakeDeviceRepository()
    let (stream, _) = makeDeviceStream()
    let registry = makeRegistry(repository: repository, stream: stream)
    let device = makeDevice(id: 3001, name: "모델 폰", pairingName: "모델")

    await registry.recordConnection(to: device)

    let saved = try #require(try await repository.device(waDeviceId: 3001))
    #expect(saved.createdAt == Date(timeIntervalSince1970: 1_000))
    #expect(saved.lastConnectedAt == Date(timeIntervalSince1970: 1_000))
  }

  @Test("저장소가 실패해도 라이브 기기를 신규 폴백 값으로 발행한다")
  func repositoryFailurePublishesFallback() async throws {
    let repository = FakeDeviceRepository(shouldFail: true)
    let (stream, continuation) = makeDeviceStream()
    let registry = makeRegistry(repository: repository, stream: stream)
    var iterator = registry.devices.makeAsyncIterator()
    let device = makeDevice(id: 4001, name: "폴백 폰", pairingName: "폴백")

    continuation.yield([device.id: device])
    let devices = try #require(await iterator.next())

    #expect(devices.count == 1)
    #expect(devices[0].isNew)
    #expect(devices[0].device.id == 4001)
  }
}

private func makeRegistry(
  repository: DeviceRepositoryProtocol,
  stream: AsyncThrowingStream<[UInt64: WAPairedDevice], any Error>
) -> WAPairedDeviceRegistry {
  WAPairedDeviceRegistry(
    repository: repository,
    deviceUpdates: { stream },
    now: { Date(timeIntervalSince1970: 1_000) },
    uuid: { UUID(uuidString: "00000000-0000-0000-0000-000000000001")! }
  )
}

private func makeDeviceStream() -> (
  AsyncThrowingStream<[UInt64: WAPairedDevice], any Error>,
  AsyncThrowingStream<[UInt64: WAPairedDevice], any Error>.Continuation
) {
  AsyncThrowingStream.makeStream(of: [UInt64: WAPairedDevice].self)
}

private func makeRecord(waDeviceId: UInt64, pairingName: String, lastConnectedAt: Date?) -> DeviceRecord {
  DeviceRecord(
    id: UUID(),
    waDeviceId: waDeviceId,
    name: pairingName,
    pairingName: pairingName,
    vendorName: "Apple",
    modelName: "iPhone",
    createdAt: Date(timeIntervalSince1970: 1),
    lastConnectedAt: lastConnectedAt
  )
}

private func makeDevice(
  id: UInt64,
  name: String,
  pairingName: String,
  vendorName: String = "Apple",
  modelName: String = "iPhone"
) -> WAPairedDevice {
  let json =
    """
    {
      "id": \(id),
      "name": "\(name)",
      "pairingInfo": {
        "pairingName": "\(pairingName)",
        "vendorName": "\(vendorName)",
        "modelName": "\(modelName)"
      }
    }
    """
  guard let device = try? JSONDecoder().decode(WAPairedDevice.self, from: Data(json.utf8)) else {
    fatalError("WAPairedDevice 테스트 fixture 디코딩에 실패했습니다")
  }
  return device
}
