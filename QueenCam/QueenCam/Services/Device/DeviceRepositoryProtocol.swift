//
//  DeviceRepositoryProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 8/10/26.
//

nonisolated protocol DeviceRepositoryProtocol: Sendable {
  func find(waDeviceId: UInt64) async throws -> StoredDeviceSnapshot?

  @discardableResult
  func upsert(
    _ incoming: StoredDeviceSnapshot,
    resolvingConflictWith resolveConflict: @Sendable (
      _ stored: StoredDeviceSnapshot,
      _ incoming: StoredDeviceSnapshot
    ) -> StoredDeviceSnapshot
  ) async throws -> (snapshot: StoredDeviceSnapshot, wasInserted: Bool)
}
