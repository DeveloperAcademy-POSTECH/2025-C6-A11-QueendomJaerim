//
//  DeviceRepositoryProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 8/10/26.
//

import Foundation

nonisolated protocol DeviceRepositoryProtocol: Sendable {
  func device(waDeviceId: UInt64) async throws -> DeviceRecord?

  @discardableResult
  func upsert(_ record: DeviceRecord) async throws -> DeviceRecord
}
