//
//  ExtendedWAPariedDevice.swift
//  QueenCam
//
//  Created by 임영택 on 1/5/26.
//

import Foundation
import WiFiAware

nonisolated struct ExtendedWAPairedDevice: Identifiable {
  var id: UInt64 {
    device.id
  }
  let device: WAPairedDevice
  let lastConnectedAt: Date?
}
