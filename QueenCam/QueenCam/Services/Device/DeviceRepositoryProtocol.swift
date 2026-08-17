//
//  DeviceRepositoryProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 8/10/26.
//

import Foundation
import WiFiAware

nonisolated protocol DeviceRepositoryProtocol: Sendable {
  func device(waDeviceId: UInt64) async throws -> StoredDeviceSnapshot?

  @discardableResult
  func upsert(_ record: StoredDeviceSnapshot) async throws -> StoredDeviceSnapshot

  func refresh(
    device: WAPairedDevice,
    id: UUID,
    discoveredAt: Date
  ) async throws -> (StoredDeviceSnapshot, Bool)
  func recordConnection(
    device: WAPairedDevice,
    id: UUID,
    connectedAt: Date
  ) async throws -> StoredDeviceSnapshot
}
