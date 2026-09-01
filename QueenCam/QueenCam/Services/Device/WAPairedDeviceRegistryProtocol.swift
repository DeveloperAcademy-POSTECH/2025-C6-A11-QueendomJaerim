//
//  WAPairedDeviceRegistryProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 8/10/26.
//

import Foundation
import WiFiAware

nonisolated protocol WAPairedDeviceRegistryProtocol: AnyObject, Sendable {
  var devices: AsyncStream<[ExtendedWAPairedDevice]> { get }

  func recordConnection(to device: WAPairedDevice) async
}
