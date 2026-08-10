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
  func device(waDeviceId: UInt64) throws -> DeviceRecord? {
    var descriptor = FetchDescriptor<StoredDevice>(
      predicate: #Predicate { device in
        device.waDeviceId == waDeviceId
      }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first.map(DeviceRecord.init(storedDevice:))
  }

  @discardableResult
  func upsert(_ record: DeviceRecord) throws -> DeviceRecord {
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
}
