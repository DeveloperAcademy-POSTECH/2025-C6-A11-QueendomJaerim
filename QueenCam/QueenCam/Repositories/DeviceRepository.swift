//
//  DeviceRepository.swift
//  QueenCam
//
//  Created by 임영택 on 8/10/26.
//

import Foundation
import SwiftData

@ModelActor
actor DeviceRepository: DeviceRepositoryProtocol {
  func find(waDeviceId: UInt64) throws -> StoredDeviceSnapshot? {
    var descriptor = FetchDescriptor<StoredDevice>(
      predicate: #Predicate { device in
        device.waDeviceId == waDeviceId
      }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first.map(StoredDeviceSnapshot.init(storedDevice:))
  }

  @discardableResult
  func upsert(
    _ incoming: StoredDeviceSnapshot,
    resolvingConflictWith resolveConflict: @Sendable (
      _ stored: StoredDeviceSnapshot,
      _ incoming: StoredDeviceSnapshot
    ) -> StoredDeviceSnapshot
  ) throws -> (snapshot: StoredDeviceSnapshot, wasInserted: Bool) {
    let waDeviceId = incoming.waDeviceId
    var descriptor = FetchDescriptor<StoredDevice>(
      predicate: #Predicate { device in
        device.waDeviceId == waDeviceId
      }
    )
    descriptor.fetchLimit = 1

    if let storedDevice = try modelContext.fetch(descriptor).first {
      let resolved = resolveConflict(StoredDeviceSnapshot(storedDevice: storedDevice), incoming)
      storedDevice.update(with: resolved)
      try modelContext.save()
      return (resolved, false)
    }

    modelContext.insert(StoredDevice(record: incoming))
    try modelContext.save()
    return (incoming, true)
  }
}
