//
//  DeviceRepositoryTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 8/10/26.
//

import Foundation
import SwiftData
import Testing

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

  private func makeRepository() throws -> (ModelContainer, DeviceRepository) {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: StoredDevice.self, configurations: configuration)
    return (container, DeviceRepository(modelContainer: container))
  }
}
