//
//  DeviceRepository.swift
//  QueenCam
//
//  Created by 임영택 on 8/10/26.
//

import Foundation
import SwiftData
import WiFiAware

@ModelActor
actor DeviceRepository: DeviceRepositoryProtocol {
  func device(waDeviceId: UInt64) throws -> StoredDeviceSnapshot? {
    var descriptor = FetchDescriptor<StoredDevice>(
      predicate: #Predicate { device in
        device.waDeviceId == waDeviceId
      }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first.map(StoredDeviceSnapshot.init(storedDevice:))
  }

  @discardableResult
  func upsert(_ record: StoredDeviceSnapshot) throws -> StoredDeviceSnapshot {
    let waDeviceId = record.waDeviceId
    var descriptor = FetchDescriptor<StoredDevice>(
      predicate: #Predicate { device in
        device.waDeviceId == waDeviceId
      }
    )
    descriptor.fetchLimit = 1

    if let storedDevice = try modelContext.fetch(descriptor).first {
      storedDevice.update(with: record)
    } else {
      modelContext.insert(StoredDevice(record: record))
    }

    try modelContext.save()
    return record
  }

  func refresh(
    device: WAPairedDevice,
    id: UUID,
    discoveredAt: Date
  ) throws -> (StoredDeviceSnapshot, Bool) {
    if let existing = try storedDevice(waDeviceId: device.id) {
      let record = StoredDeviceSnapshot(storedDevice: existing).merging(device: device)
      existing.update(with: record)
      try modelContext.save()
      return (record, false)
    }
    let record = StoredDeviceSnapshot(id: id, device: device, createdAt: discoveredAt, lastConnectedAt: nil)
    modelContext.insert(StoredDevice(record: record))
    try modelContext.save()
    return (record, true)
  }

  func recordConnection(
    device: WAPairedDevice,
    id: UUID,
    connectedAt: Date
  ) throws -> StoredDeviceSnapshot {
    let record: StoredDeviceSnapshot
    if let existing = try storedDevice(waDeviceId: device.id) {
      record = StoredDeviceSnapshot(storedDevice: existing)
        .merging(device: device, lastConnectedAt: connectedAt)
      existing.update(with: record)
    } else {
      record = StoredDeviceSnapshot(
        id: id,
        device: device,
        createdAt: connectedAt,
        lastConnectedAt: connectedAt
      )
      modelContext.insert(StoredDevice(record: record))
    }
    try modelContext.save()
    return record
  }

  private func storedDevice(waDeviceId: UInt64) throws -> StoredDevice? {
    var descriptor = FetchDescriptor<StoredDevice>(
      predicate: #Predicate { device in device.waDeviceId == waDeviceId }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }
}
