//
//  ExtendedWAPairedDevice.swift
//  QueenCam
//
//  Created by 임영택 on 8/10/26.
//

import Foundation
import WiFiAware

nonisolated struct DeviceMetadata: Equatable, Sendable {
  let name: String
  let pairingName: String?
  let vendorName: String?
  let modelName: String?

  init(device: WAPairedDevice) {
    name = device.name ?? ""
    pairingName = device.pairingInfo?.pairingName
    vendorName = device.pairingInfo?.vendorName
    modelName = device.pairingInfo?.modelName
  }
}

nonisolated struct ExtendedWAPairedDevice: Identifiable, Sendable {
  let id: UUID
  let device: WAPairedDevice
  let name: String
  let pairingName: String?
  let vendorName: String?
  let modelName: String?
  let createdAt: Date
  let lastConnectedAt: Date?
  let isNew: Bool

  init(device: WAPairedDevice, record: DeviceRecord, isNew: Bool) {
    id = record.id
    self.device = device
    name = record.name
    pairingName = record.pairingName
    vendorName = record.vendorName
    modelName = record.modelName
    createdAt = record.createdAt
    lastConnectedAt = record.lastConnectedAt
    self.isNew = isNew
  }

  var record: DeviceRecord {
    DeviceRecord(
      id: id,
      waDeviceId: device.id,
      name: name,
      pairingName: pairingName,
      vendorName: vendorName,
      modelName: modelName,
      createdAt: createdAt,
      lastConnectedAt: lastConnectedAt
    )
  }
}

nonisolated extension DeviceRecord {
  init(
    id: UUID,
    device: WAPairedDevice,
    createdAt: Date,
    lastConnectedAt: Date?
  ) {
    let metadata = DeviceMetadata(device: device)
    self.init(
      id: id,
      waDeviceId: device.id,
      name: metadata.name,
      pairingName: metadata.pairingName,
      vendorName: metadata.vendorName,
      modelName: metadata.modelName,
      createdAt: createdAt,
      lastConnectedAt: lastConnectedAt
    )
  }

  func merging(device: WAPairedDevice, lastConnectedAt: Date? = nil) -> DeviceRecord {
    let metadata = DeviceMetadata(device: device)
    return DeviceRecord(
      id: id,
      waDeviceId: waDeviceId,
      name: metadata.name,
      pairingName: metadata.pairingName,
      vendorName: metadata.vendorName,
      modelName: metadata.modelName,
      createdAt: createdAt,
      lastConnectedAt: lastConnectedAt ?? self.lastConnectedAt
    )
  }

  var metadata: DeviceMetadata {
    DeviceMetadata(
      name: name,
      pairingName: pairingName,
      vendorName: vendorName,
      modelName: modelName
    )
  }
}

nonisolated private extension DeviceMetadata {
  init(name: String, pairingName: String?, vendorName: String?, modelName: String?) {
    self.name = name
    self.pairingName = pairingName
    self.vendorName = vendorName
    self.modelName = modelName
  }
}
