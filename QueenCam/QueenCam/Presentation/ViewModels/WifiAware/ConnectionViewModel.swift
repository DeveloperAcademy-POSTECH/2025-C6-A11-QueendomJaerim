//
//  ConnectionViewModel.swift
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
final class ConnectionViewModel {
  private(set) var role: Role?
  var pairedDevices: [WAPairedDevice] = []

  var networkState: NetworkState?
  var connections: [WAPairedDevice: ConnectionDetail] = [:]
  var connectedDevice: WAPairedDevice? {
    connections.keys.first
  }
  var connectedDeviceName: String? {
    connectedDevice?.pairingInfo?.pairingName
  }
  var lastConnectedDevice: WAPairedDevice?

  var lastPingAt: Date?

  /// 연결 유실 여부를 표현하는 플래그. true이면 재연결을 시작하고 관련 UI를 표시
  var connectionLost: Bool = false

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

        // 이벤트 전파 후 핸들링
        if state == .host(.cancelled) || state == .viewer(.cancelled) {
          role = nil
        }
        if state == .host(.lost) || state == .viewer(.lost) {
          connectionLost = true
          tryReconnect()
        }
      }
      .store(in: &cancellables)

    networkService.deviceConnectionsPublisher
      .compactMap { $0 }
      .sink { [weak self] connections in
        self?.connections = connections

        // 이벤트 전파 후 핸들링
        self?.didEstablishConnection(connections: connections)
      }
      .store(in: &cancellables)

    networkService.networkEventPublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] event in
        switch event {
        case .ping(let pingAt):
          self?.lastPingAt = pingAt
        case .requestChangeRole(let myNewRole):
          self?.handleReceivedRequestChangeRole(newRole: myNewRole)
        case .acceptChangeRole(let counterpartNewRole):
          self?.handleReceivedAcceptChangeRole(counterpartNewRole: counterpartNewRole)
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

extension ConnectionViewModel {
  func didEndpointSelect(endpoint: WASubscriberBrowser.Endpoint) {
    logger.info("endpoint selected. \(endpoint)")
  }

  func connectButtonDidTap(for device: WAPairedDevice) {
    if role == .model {
      networkService.mode = .viewer
    } else if role == .photographer {
      networkService.mode = .host
    }

    if networkState == .host(.stopped) || networkState == .viewer(.stopped) {
      networkService.run(for: device)
    }
  }

  func disconnectButtonDidTap() {
    networkService.disconnect()
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
      networkService.stop(byUser: true)
    }
  }

  func selectRole(for role: Role?) {
    self.role = role
  }

  func swapRole() {
    guard let role else {
      logger.warning("The user requested to swap current role but it is nil. skipping.")
      return
    }

    Task.detached {
      // 상대에게 지금 나의 현재 역할로 바꾸라고 요청한다
      await self.networkService.send(for: .requestChangeRole(yourNewRole: role))
    }
  }

  func reconnectCancelButtonDidTap() {
    networkService.stop(byUser: true)
    lastConnectedDevice = nil
    connectionLost = false
  }
}

// MARK: - Connecting
extension ConnectionViewModel {
  private func didEstablishConnection(connections: [WAPairedDevice: ConnectionDetail]) {
    if let firstConnection = connections.first {
      lastConnectedDevice = firstConnection.key
      connectionLost = false  // 재연결인 경우 connectionLost 플래그를 초기화
    }
  }

  private func tryReconnect() {
    if let lastConnectedDevice {
      logger.info("try to reconnect to \(lastConnectedDevice)")
      networkService.run(for: lastConnectedDevice)
    } else {
      logger.warning("최근 연결한 디바이스 정보가 없어 재연결에 실패했습니다.")
    }
  }
}

// MARK: - Incomming NetworkEvent Handler
extension ConnectionViewModel {
  private func handleReceivedRequestChangeRole(newRole: Role) {
    Task.detached {
      await self.networkService.send(for: .acceptChangeRole(myNewRole: newRole))
    }

    role = newRole
  }

  private func handleReceivedAcceptChangeRole(counterpartNewRole: Role) {
    if let myCurrentRole = role,
      counterpartNewRole == myCurrentRole {
      role = myCurrentRole.counterpart
    } else {
      logger.error("failed to change role... inconsistency in roles")
      networkService.stop(byUser: false)
    }
  }
}
