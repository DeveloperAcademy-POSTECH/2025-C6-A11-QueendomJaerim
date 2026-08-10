//
//  DeviceRepositoryTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 8/10/26.
//

import Foundation
import SwiftData
import Testing
import WiFiAware

@testable import QueenCam

@Suite("DeviceRepository Tests")
struct DeviceRepositoryTests {
  @Test("새 상대 기기를 저장하고 Wi-Fi Aware 식별자로 조회한다")
  func insertsAndFetchesDevice() async throws {
    let (_, repository) = try makeRepository()
    let record = DeviceRecord(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      waDeviceId: 1001,
      name: "작가의 iPhone",
      pairingName: "작가",
      vendorName: "Apple",
      modelName: "iPhone",
      createdAt: Date(timeIntervalSince1970: 100),
      lastConnectedAt: nil
    )

    let saved = try await repository.upsert(record)
    let fetched = try await repository.device(waDeviceId: 1001)

    #expect(saved == record)
    #expect(fetched == record)
  }

  @Test("같은 Wi-Fi Aware 식별자는 새 행을 만들지 않고 메타데이터를 갱신한다")
  func updatesSameWADeviceID() async throws {
    let (container, repository) = try makeRepository()
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    let createdAt = Date(timeIntervalSince1970: 200)
    let lastConnectedAt = Date(timeIntervalSince1970: 300)
    let original = DeviceRecord(
      id: id,
      waDeviceId: 1002,
      name: "이전 이름",
      pairingName: "이전 페어링 이름",
      vendorName: "이전 제조사",
      modelName: "이전 모델",
      createdAt: createdAt,
      lastConnectedAt: lastConnectedAt
    )
    let updated = DeviceRecord(
      id: id,
      waDeviceId: 1002,
      name: "현재 이름",
      pairingName: "현재 페어링 이름",
      vendorName: "Apple",
      modelName: "iPhone 17 Pro",
      createdAt: createdAt,
      lastConnectedAt: lastConnectedAt
    )

    _ = try await repository.upsert(original)
    _ = try await repository.upsert(updated)

    let fetched = try await repository.device(waDeviceId: 1002)
    let count = try await MainActor.run {
      try container.mainContext.fetchCount(FetchDescriptor<StoredDevice>())
    }
    #expect(fetched == updated)
    #expect(count == 1)
  }

  @Test("메타데이터 갱신은 기존 식별자와 날짜를 보존한다")
  func refreshPreservesIdentityAndDates() async throws {
    let (_, repository) = try makeRepository()
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    let createdAt = Date(timeIntervalSince1970: 10)
    let connectedAt = Date(timeIntervalSince1970: 20)
    let original = DeviceRecord(
      id: id, waDeviceId: 1003, name: "이전", pairingName: "이전", vendorName: nil,
      modelName: nil, createdAt: createdAt, lastConnectedAt: connectedAt
    )
    _ = try await repository.upsert(original)

    let current = makeRepositoryDevice(id: 1003, name: "현재")
    let (refreshed, isNew) = try await repository.refresh(
      device: current,
      id: UUID(),
      discoveredAt: Date(timeIntervalSince1970: 30)
    )

    #expect(isNew == false)
    #expect(refreshed.id == id)
    #expect(refreshed.createdAt == createdAt)
    #expect(refreshed.lastConnectedAt == connectedAt)
    #expect(refreshed.pairingName == "현재")
  }

  private func makeRepository() throws -> (ModelContainer, DeviceRepository) {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: StoredDevice.self, configurations: configuration)
    return (container, DeviceRepository(modelContainer: container))
  }
}

private func makeRepositoryDevice(id: UInt64, name: String) -> WAPairedDevice {
  let json = "{\"id\":\(id),\"name\":\"\(name)\",\"pairingInfo\":"
    + "{\"pairingName\":\"\(name)\",\"vendorName\":\"Apple\",\"modelName\":\"iPhone\"}}"
  guard let device = try? JSONDecoder().decode(WAPairedDevice.self, from: Data(json.utf8)) else {
    fatalError("WAPairedDevice 테스트 fixture 디코딩에 실패했습니다")
  }
  return device
}
