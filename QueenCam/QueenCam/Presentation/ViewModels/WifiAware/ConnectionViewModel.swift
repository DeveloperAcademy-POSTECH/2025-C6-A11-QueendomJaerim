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
  private(set) var role: Role? {
    didSet {
      if let role {
        NotificationCenter.default.post(
          name: .QueenCamRoleChangedNotification,
          object: nil,
          userInfo: ["newRole": role as Any]
        )
      }
    }
  }
  private(set) var pairedDevices: [WAPairedDevice] = []
  private(set) var selectedPairedDevice: WAPairedDevice?

  var networkState: NetworkState? {
    didSet {
      // 연결 상태 변화에 따른 State Toast 처리
      // 그 외 사이드 이펙트가 따라오는 다른 작업은 최대한 피할 것

      if networkState == .host(.stopped) || networkState == .viewer(.stopped) {
        notificationService.registerBaseNotification(DomainNotification.make(type: .ready))
      } else {
        notificationService.resetBaseNotification()
      }
    }
  }
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
  /// 재연결 중인 디바이스 이름
  var reconnectingDeviceName: String?
  
  var needReportSessionFinished: Bool = false

  /// 최근 역할 스왑 LWW 기록
  private var lastSwapRoleLWWRegister: LWWRegister?
  private let myLWWActorId: String = UUID().uuidString

  private let networkService: NetworkServiceProtocol
  private var cancellables: Set<AnyCancellable> = []

  var isConnecting: Bool {
    !(networkState == nil || networkState == .host(.stopped) || networkState == .viewer(.stopped))
  }

  /// State Toast
  private let notificationService: NotificationServiceProtocol

  private let logger = QueenLogger(category: "ConnectionViewModel")

  init(networkService: NetworkServiceProtocol, notificationService: NotificationServiceProtocol) {
    self.networkService = networkService
    self.notificationService = notificationService
    bind()

    // @Observable ViewModel은 두 번 초기화될 수 있음
    // https://stackoverflow.com/a/78222019
    // 두번쨰 초기화되면 알림을 다시 초기화하지 않도록 nil일때만 초기화함
    if notificationService.currentNotification == nil {
      notificationService.registerBaseNotification(DomainNotification.make(type: .ready))
    }
  }

  private func bind() {
    networkService.networkStatePublisher
      .compactMap { $0 }
      .sink { [weak self] state in
        guard let self else { return }
        self.networkState = state

        // 이벤트 전파 후 핸들링
        if state == .host(.lost) || state == .viewer(.lost) {
          connectionLost = true
          reconnectingDeviceName = lastConnectedDevice?.name
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
        case .changeRole(let roles, let lwwValue):
          self?.handleReceivedRequestChangeRole(receivedNewRoles: roles, receviedLwwRegister: lwwValue)
        case .willDisconnect:
          // 상대로부터 연결 종료 예정 통보를 받으면 세션 종료 오버레이 노출
          self?.needReportSessionFinished = true
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
    selectedPairedDevice = device

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
    role = nil // 정상 종료인 경우 역할 초기화
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
    networkService.stop(byUser: true)
    self.role = role
  }

  func swapRole() {
    guard let role else {
      logger.warning("The user requested to swap current role but it is nil. skipping.")
      return
    }

    let lwwValue = LWWRegister(actorId: myLWWActorId, timestamp: Date())
    lastSwapRoleLWWRegister = lwwValue

    self.role = role.counterpart

    Task.detached {
      // 상대에게 지금 나의 현재 역할로 바꾸라고 요청한다
      await self.networkService.send(for: .changeRole(.init(myRole: role.counterpart), lwwValue))
    }
  }

  func reconnectCancelButtonDidTap() {
    networkService.stop(byUser: true)
    lastConnectedDevice = nil
    connectionLost = false
    reconnectingDeviceName = nil
  }

  func sessionFinishedOverlayCloseButtonDidTap() {
    needReportSessionFinished = false
    role = nil // 정상 종료인 경우 역할 초기화
  }
}

// MARK: - Connecting
extension ConnectionViewModel {
  private func didEstablishConnection(connections: [WAPairedDevice: ConnectionDetail]) {
    if let firstConnection = connections.first {
      lastConnectedDevice = firstConnection.key
      connectionLost = false  // 재연결인 경우 connectionLost 플래그를 초기화
      reconnectingDeviceName = nil
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
  private func handleReceivedRequestChangeRole(receivedNewRoles: RolePayload, receviedLwwRegister: LWWRegister) {
    let newMyRole = receivedNewRoles.counterpartRole

    if let lastSwapRoleLWWRegister {
      if receviedLwwRegister.timestamp > lastSwapRoleLWWRegister.timestamp { // 타임스탬프가 최근이면 채택
        updateRole(with: newMyRole, lwwRegister: receviedLwwRegister)
      } else if receviedLwwRegister.timestamp == lastSwapRoleLWWRegister.timestamp,
        receviedLwwRegister.actorId > lastSwapRoleLWWRegister.actorId { // 타임스탬프가 같으면 actorId가 앞에 있을 때 채택
        updateRole(with: newMyRole, lwwRegister: receviedLwwRegister)
      } else {
        logger.warning("Received swapping role request but I already have the latest value, skipping.")
      }
    } else {
      updateRole(with: newMyRole, lwwRegister: receviedLwwRegister)
    }
  }

  private func updateRole(with newRole: Role, lwwRegister: LWWRegister) {
    logger.debug("Role updated to \(newRole.displayName) (lwwRegister: \(lwwRegister)")
    self.role = newRole
    self.lastSwapRoleLWWRegister = lwwRegister
  }
}
