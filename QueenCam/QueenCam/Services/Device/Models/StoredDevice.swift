//
//  StoredDevice.swift
//  QueenCam
//
//  Created by 임영택 on 8/10/26.
//

import Foundation
import SwiftData

@Model
final class StoredDevice {
  @Attribute(.unique) var waDeviceId: UInt64
  var id: UUID
  var name: String
  var pairingName: String?
  var vendorName: String?
  var modelName: String?
  var createdAt: Date
  var lastConnectedAt: Date?

  init(record: DeviceRecord) {
    self.waDeviceId = record.waDeviceId
    self.id = record.id
    self.name = record.name
    self.pairingName = record.pairingName
    self.vendorName = record.vendorName
    self.modelName = record.modelName
    self.createdAt = record.createdAt
    self.lastConnectedAt = record.lastConnectedAt
  }

  func update(with record: DeviceRecord) {
    id = record.id
    name = record.name
    pairingName = record.pairingName
    vendorName = record.vendorName
    modelName = record.modelName
    createdAt = record.createdAt
    lastConnectedAt = record.lastConnectedAt
  }
}

nonisolated struct DeviceRecord: Equatable, Sendable {
  let id: UUID
  let waDeviceId: UInt64
  let name: String
  let pairingName: String?
  let vendorName: String?
  let modelName: String?
  let createdAt: Date
  let lastConnectedAt: Date?

  init(
    id: UUID,
    waDeviceId: UInt64,
    name: String,
    pairingName: String?,
    vendorName: String?,
    modelName: String?,
    createdAt: Date,
    lastConnectedAt: Date?
  ) {
    self.id = id
    self.waDeviceId = waDeviceId
    self.name = name
    self.pairingName = pairingName
    self.vendorName = vendorName
    self.modelName = modelName
    self.createdAt = createdAt
    self.lastConnectedAt = lastConnectedAt
  }

  init(storedDevice: StoredDevice) {
    self.init(
      id: storedDevice.id,
      waDeviceId: storedDevice.waDeviceId,
      name: storedDevice.name,
      pairingName: storedDevice.pairingName,
      vendorName: storedDevice.vendorName,
      modelName: storedDevice.modelName,
      createdAt: storedDevice.createdAt,
      lastConnectedAt: storedDevice.lastConnectedAt
    )
  }
}
