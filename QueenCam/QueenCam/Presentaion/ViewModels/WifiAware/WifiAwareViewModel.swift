//
//  WifiAwareViewModel.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Combine
import Foundation
import OSLog
import WiFiAware

@Observable
@MainActor
final class WifiAwareViewModel {
  var role: Role? {
    didSet {
      if role == .model {
        networkService.mode = .viewer
      } else if role == .photographer {
        networkService.mode = .host
      }
    }
  }
  var pairedDevices: [WAPairedDevice] = []

  var networkState: NetworkState?
  var connections: [WAPairedDevice: ConnectionDetail] = [:]

  private let networkService: NetworkServiceProtocol
  private var cancellables: Set<AnyCancellable> = []

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "ConnectionView")

  init(networkService: NetworkServiceProtocol) {
    self.networkService = networkService
    bind()
  }

  private func bind() {
    networkService.networkStatePublisher
      .compactMap { $0 }
      .sink { [weak self] state in
        self?.networkState = state
      }
      .store(in: &cancellables)

    networkService.deviceConnectionsPublisher
      .compactMap { $0 }
      .sink { [weak self] connections in
        self?.connections = connections
      }
      .store(in: &cancellables)

    networkService.networkEventPublisher
      .compactMap { $0 }
      .sink { event in
        // TODO: Handle events
      }
      .store(in: &cancellables)
  }

  private func updatePairedDevices() async {
    do {
      for try await updatedDeviceList in WAPairedDevice.allDevices {
        let devices = Array(updatedDeviceList.values)
        self.pairedDevices = devices
        logger.info("pairedDevices updated.\n\(devices)")
      }
    } catch {
      logger.error("Failed to get paired devices: \(error)")
    }
  }
}

extension WifiAwareViewModel {
  func didEndpointSelect(endpoint: WASubscriberBrowser.Endpoint) {
    logger.info("endpoint selected. \(endpoint)")
  }

  func connectButtonTapped(for device: WAPairedDevice) {
    if networkState == .host(.stopped) || networkState == .viewer(.stopped) {
      networkService.run(for: device)
    } else {
      networkService.stop()
    }
  }

  func viewDidAppearTask() async {
    await updatePairedDevices()
  }
}
