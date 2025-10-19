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
  private(set) var role: Role? {
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
  var connectedDevice: WAPairedDevice? {
    connections.keys.first
  }
  var connectedDeviceName: String? {
    connectedDevice?.pairingInfo?.pairingName
  }

  var lastPingAt: Date?

  private let networkService: NetworkServiceProtocol
  private var cancellables: Set<AnyCancellable> = []

  var isConnecting: Bool {
    !(networkState == nil || networkState == .host(.stopped) || networkState == .viewer(.stopped))
  }

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "ConnectionView")

  init(networkService: NetworkServiceProtocol) {
    self.networkService = networkService
    bind()
  }

  private func bind() {
    networkService.networkStatePublisher
      .compactMap { $0 }
      .sink { [weak self] state in
        guard let self else { return }
        self.networkState = state
        if state == .host(.cancelled) || state == .viewer(.cancelled) {
          role = nil
        }
      }
      .store(in: &cancellables)

    networkService.deviceConnectionsPublisher
      .compactMap { $0 }
      .sink { [weak self] connections in
        self?.connections = connections
      }
      .store(in: &cancellables)

    networkService.networkEventPublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] event in
        switch event {
        case .ping(let pingAt):
          self?.lastPingAt = pingAt
        default: break
        }
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

  func connectButtonDidTap(for device: WAPairedDevice) {
    if networkState == .host(.stopped) || networkState == .viewer(.stopped) {
      networkService.run(for: device)
    }
  }

  func disconnectButtonDidTap() {
    networkService.stop()
  }

  func viewDidAppearTask() async {
    await updatePairedDevices()
  }

  func pingButtonDidTap() {
    Task.detached {
      await self.networkService.send(for: .ping(Date()))
    }
  }

  func connectionViewDisappear() {
    if connections.isEmpty {  // 연결 중인 경우 연결 뷰에서 벗어나면 연결을 취소한다
      networkService.stop()
    }
  }

  func selectRole(for role: Role?) {
    self.role = role
  }
}
