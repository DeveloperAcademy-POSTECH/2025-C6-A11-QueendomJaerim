//
//  SessionLogRepository.swift
//  QueenCam
//
//  Created by 임영택 on 1/5/26.
//

import Foundation
import OSLog
import WiFiAware

actor WAPairedDevicesRepository {
  let allDevices: AsyncStream<[ExtendedWAPairedDevice]>
  private let allDevicesContinuation: AsyncStream<[ExtendedWAPairedDevice]>.Continuation

  var connectedDevices: [UInt64: ExtendedWAPairedDevice] = [:]

  private var handleUpstreamAllDevicesStreamTask: Task<Void, Never>?

  private let looger: QueenLogger = .init(category: "WAPairedDevicesRepository")

  init(connectedDevices: [ExtendedWAPairedDevice] = []) {
    (self.allDevices, self.allDevicesContinuation) = AsyncStream.makeStream(of: Array<ExtendedWAPairedDevice>.self)
    Task {
      await handleUpstreamAllDevicesStream()
    }
  }

  deinit {
    handleUpstreamAllDevicesStreamTask?.cancel()
  }

  func handleUpstreamAllDevicesStream() {
    handleUpstreamAllDevicesStreamTask?.cancel()
    handleUpstreamAllDevicesStreamTask = Task {
      do {
        for try await updatedDeviceList in WAPairedDevice.allDevices {
          updatedDeviceList.values.forEach { device in
            connectedDevices[device.id] = .init(
              device: device,
              lastConnectedAt: connectedDevices[device.id]?.lastConnectedAt ?? nil
            )
          }

          allDevicesContinuation.yield(Array(connectedDevices.values))
        }
      } catch {
        looger.error("error on iterating all wifi aware paired devices: \(error)")
      }
    }
  }

  func save(for device: ExtendedWAPairedDevice) {
    connectedDevices[device.id] = device
    allDevicesContinuation.yield(Array(connectedDevices.values))
  }
}
