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
    let record = StoredDeviceSnapshot(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      waDeviceId: 1001,
      name: "작가의 iPhone",
      pairingName: "작가",
      vendorName: "Apple",
      modelName: "iPhone",
      createdAt: Date(timeIntervalSince1970: 100),
      lastConnectedAt: nil
    )

    let (saved, wasInserted) = try await repository.upsert(record) { _, incoming in incoming }
    let fetched = try await repository.find(waDeviceId: 1001)

    #expect(saved == record)
    #expect(wasInserted)
    #expect(fetched == record)
  }

  @Test("같은 Wi-Fi Aware 식별자는 새 행을 만들지 않고 메타데이터를 갱신한다")
  func updatesSameWADeviceID() async throws {
    let (container, repository) = try makeRepository()
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    let createdAt = Date(timeIntervalSince1970: 200)
    let lastConnectedAt = Date(timeIntervalSince1970: 300)
    let original = StoredDeviceSnapshot(
      id: id,
      waDeviceId: 1002,
      name: "이전 이름",
      pairingName: "이전 페어링 이름",
      vendorName: "이전 제조사",
      modelName: "이전 모델",
      createdAt: createdAt,
      lastConnectedAt: lastConnectedAt
    )
    let updated = StoredDeviceSnapshot(
      id: id,
      waDeviceId: 1002,
      name: "현재 이름",
      pairingName: "현재 페어링 이름",
      vendorName: "Apple",
      modelName: "iPhone 17 Pro",
      createdAt: createdAt,
      lastConnectedAt: lastConnectedAt
    )

    _ = try await repository.upsert(original) { _, incoming in incoming }
    let (saved, wasInserted) = try await repository.upsert(updated) { _, incoming in incoming }

    let fetched = try await repository.find(waDeviceId: 1002)
    let count = try await MainActor.run {
      try container.mainContext.fetchCount(FetchDescriptor<StoredDevice>())
    }
    #expect(saved == updated)
    #expect(wasInserted == false)
    #expect(fetched == updated)
    #expect(count == 1)
  }

  @Test("충돌 해결 결과를 같은 행에 원자적으로 저장한다")
  func resolvesConflictAtomically() async throws {
    let (_, repository) = try makeRepository()
    let id = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    let createdAt = Date(timeIntervalSince1970: 10)
    let connectedAt = Date(timeIntervalSince1970: 20)
    let original = StoredDeviceSnapshot(
      id: id, waDeviceId: 1003, name: "이전", pairingName: "이전", vendorName: nil,
      modelName: nil, createdAt: createdAt, lastConnectedAt: connectedAt
    )
    let incoming = StoredDeviceSnapshot(
      id: UUID(), waDeviceId: 1003, name: "현재", pairingName: "현재", vendorName: "Apple",
      modelName: "iPhone", createdAt: Date(timeIntervalSince1970: 30), lastConnectedAt: nil
    )
    _ = try await repository.upsert(original) { _, incoming in incoming }

    let (resolved, wasInserted) = try await repository.upsert(incoming) { stored, incoming in
      StoredDeviceSnapshot(
        id: stored.id,
        waDeviceId: stored.waDeviceId,
        name: incoming.name,
        pairingName: incoming.pairingName,
        vendorName: incoming.vendorName,
        modelName: incoming.modelName,
        createdAt: stored.createdAt,
        lastConnectedAt: stored.lastConnectedAt
      )
    }
    let fetched = try await repository.find(waDeviceId: 1003)

    #expect(wasInserted == false)
    #expect(resolved.id == id)
    #expect(resolved.createdAt == createdAt)
    #expect(resolved.lastConnectedAt == connectedAt)
    #expect(resolved.pairingName == "현재")
    #expect(fetched == resolved)
  }

  private func makeRepository() throws -> (ModelContainer, DeviceRepository) {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: StoredDevice.self, configurations: configuration)
    return (container, DeviceRepository(modelContainer: container))
  }
}
