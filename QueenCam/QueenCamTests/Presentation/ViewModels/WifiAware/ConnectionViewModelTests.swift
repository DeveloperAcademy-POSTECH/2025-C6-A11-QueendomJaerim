//
//  ConnectionViewModelTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 8/22/26.
//

import Combine
import Foundation
import Testing
import WiFiAware

@testable import QueenCam

@Suite("ConnectionViewModel Tests")
@MainActor
struct ConnectionViewModelTests {
  @Test("역할 후보를 선택하고 확정한 뒤 이전 단계로 돌아간다")
  func transitionsRoleSelectionState() {
    let viewModel = makeViewModel()

    viewModel.connectionViewAppear()
    #expect(viewModel.connectionV2Step == .roleSelection)
    #expect(viewModel.pendingRole == nil)

    viewModel.pendingRoleDidSelect(.photographer)
    #expect(viewModel.pendingRole == .photographer)
    #expect(viewModel.role == nil)

    viewModel.pendingRoleDidConfirm()
    #expect(viewModel.connectionV2Step == .deviceList)
    #expect(viewModel.role == .photographer)

    viewModel.connectionV2BackButtonDidTap()
    #expect(viewModel.connectionV2Step == .roleSelection)
    #expect(viewModel.pendingRole == .photographer)
    #expect(viewModel.role == nil)
  }

  @Test("같은 역할 후보를 다시 누르면 선택을 해제한다")
  func togglesPendingRole() {
    let viewModel = makeViewModel()

    viewModel.pendingRoleDidSelect(.model)
    viewModel.pendingRoleDidSelect(.model)

    #expect(viewModel.pendingRole == nil)
    #expect(viewModel.connectionV2Step == .roleSelection)
  }

  @Test("연결 시작과 중단 상태를 V2 표시 상태로 변환한다")
  func mapsConnectingAndStoppedState() async {
    let networkService = FakeNetworkService()
    let viewModel = makeViewModel(networkService: networkService)
    let device = makeExtendedDevice(id: 2001, pairingName: "친구의 iPhone").device
    viewModel.pendingRoleDidSelect(.model)
    viewModel.pendingRoleDidConfirm()

    viewModel.connectButtonDidTap(for: device)
    let didSelect = await waitUntil { viewModel.selectedPairedDevice?.id == 2001 }
    #expect(didSelect)
    #expect(networkService.mode == .viewer)
    #expect(networkService.lastRunDevice?.id == 2001)

    networkService.networkStateSubject.send(.viewer(.connecting))
    #expect(viewModel.connectionAttemptState == .connecting(deviceName: "친구의 iPhone"))

    viewModel.stopConnectingButtonDidTap()
    #expect(viewModel.connectionAttemptState == .idle)
    #expect(networkService.stopCallCount >= 2)
  }

  @Test("연결 오류를 실패 상태로 표시하고 확인 시 소비한다")
  func consumesConnectionError() async {
    let networkService = FakeNetworkService()
    let viewModel = makeViewModel(networkService: networkService)

    networkService.lastErrorSubject.send(TestConnectionError.failed)
    let didReceiveError = await waitUntil { viewModel.connectionAttemptState == .failed }
    #expect(didReceiveError)

    viewModel.errorConfirmedByUser()
    #expect(viewModel.connectionAttemptState == .idle)
    #expect(viewModel.connectionError == nil)
  }

  @Test("기기 연결 이력 상태와 문구를 만든다")
  func mapsDeviceConnectionHistory() {
    let newDevice = makeExtendedDevice(id: 3001, pairingName: "새 기기")
    let neverConnected = makeExtendedDevice(id: 3002, pairingName: "기록 없는 기기", isNew: false)
    let connectedAt = Date(timeIntervalSince1970: 1_770_681_600)
    let recentlyConnected = makeExtendedDevice(
      id: 3003,
      pairingName: "최근 기기",
      isNew: false,
      lastConnectedAt: connectedAt
    )

    #expect(ConnectionDeviceRowState(device: newDevice).historyStatus.localizedText == "새로 등록된 기기")
    #expect(ConnectionDeviceRowState(device: neverConnected).historyStatus.localizedText == "최근 연결 기록이 없어요.")
    #expect(
      ConnectionDeviceRowState(device: recentlyConnected).historyStatus.localizedText
        .hasPrefix("최근 연결: 26. 2. 10")
    )
  }

  @Test("화면이 사라진 뒤에도 페어링 기기 업데이트를 받는다")
  func keepsObservingPairedDevicesAfterViewDisappears() async throws {
    let (devices, continuation) = AsyncStream.makeStream(of: [ExtendedWAPairedDevice].self)
    let registry = FakePairedDeviceRegistry(devices: devices)
    let viewModel = ConnectionViewModel(
      networkService: FakeNetworkService(),
      notificationService: FakeNotificationService(),
      pairedDeviceRegistry: registry
    )
    let first = makeExtendedDevice(id: 1001, pairingName: "첫 기기")
    continuation.yield([first])
    let receivedFirst = await waitUntil { viewModel.pairedDevices.map(\.device.id) == [1001] }
    #expect(receivedFirst)

    viewModel.connectionViewDisappear()
    let second = makeExtendedDevice(id: 1002, pairingName: "둘째 기기")
    continuation.yield([second])
    let receivedSecond = await waitUntil { viewModel.pairedDevices.map(\.device.id) == [1002] }

    #expect(receivedSecond)
  }
}

@MainActor
private func makeViewModel(networkService: FakeNetworkService = FakeNetworkService()) -> ConnectionViewModel {
  let (devices, _) = AsyncStream.makeStream(of: [ExtendedWAPairedDevice].self)
  return ConnectionViewModel(
    networkService: networkService,
    notificationService: FakeNotificationService(),
    pairedDeviceRegistry: FakePairedDeviceRegistry(devices: devices)
  )
}

private final class FakePairedDeviceRegistry: WAPairedDeviceRegistryProtocol, @unchecked Sendable {
  let devices: AsyncStream<[ExtendedWAPairedDevice]>

  init(devices: AsyncStream<[ExtendedWAPairedDevice]>) {
    self.devices = devices
  }

  func recordConnection(to device: WAPairedDevice) async {}
}

private final class FakeNetworkService: NetworkServiceProtocol {
  var mode: NetworkType?
  var networkState: NetworkState?
  var lastStopReason: String?
  let lastErrorSubject = PassthroughSubject<Error?, Never>()
  let networkStateSubject = PassthroughSubject<NetworkState?, Never>()
  private(set) var lastRunDevice: WAPairedDevice?
  private(set) var stopCallCount = 0

  var deviceConnectionsPublisher: AnyPublisher<[WAPairedDevice: ConnectionDetail], Never> {
    Empty().eraseToAnyPublisher()
  }

  var lastErrorPublisher: AnyPublisher<Error?, Never> {
    lastErrorSubject.eraseToAnyPublisher()
  }

  var networkStatePublisher: AnyPublisher<NetworkState?, Never> {
    networkStateSubject.eraseToAnyPublisher()
  }

  var networkEventPublisher: AnyPublisher<NetworkEvent?, Never> {
    Empty().eraseToAnyPublisher()
  }

  var deviceReportsPublisher: AnyPublisher<[WAPairedDevice: WAPerformanceReport], Never> {
    Empty().eraseToAnyPublisher()
  }

  func run(for device: WAPairedDevice) {
    lastRunDevice = device
  }
  func reconnect(for device: WAPairedDevice) {}
  func stop(byUser: Bool, userReason: String?) {
    stopCallCount += 1
  }
  func disconnect() {}
  func send(for event: NetworkEvent) async {}
}

private final class FakeNotificationService: NotificationServiceProtocol {
  var currentNotification: DomainNotification?

  var lastNotificationPublisher: AnyPublisher<DomainNotification?, Never> {
    Empty().eraseToAnyPublisher()
  }

  func registerNotification(_ notification: DomainNotification) {
    currentNotification = notification
  }

  func reset() {
    currentNotification = nil
  }

  func registerBaseNotification(_ notification: DomainNotification) {
    currentNotification = notification
  }

  func resetBaseNotification() {
    currentNotification = nil
  }
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async -> Bool {
  for _ in 0..<100 {
    if condition() { return true }
    try? await Task.sleep(for: .milliseconds(10))
  }
  return false
}

private enum TestConnectionError: Error {
  case failed
}

private func makeExtendedDevice(
  id: UInt64,
  pairingName: String,
  isNew: Bool = true,
  lastConnectedAt: Date? = nil
) -> ExtendedWAPairedDevice {
  let json =
    """
    {
      "id": \(id),
      "name": "\(pairingName)",
      "pairingInfo": {
        "pairingName": "\(pairingName)",
        "vendorName": "Apple",
        "modelName": "iPhone"
      }
    }
    """
  guard let device = try? JSONDecoder().decode(WAPairedDevice.self, from: Data(json.utf8)) else {
    fatalError("WAPairedDevice 테스트 fixture 디코딩에 실패했습니다")
  }
  let record = StoredDeviceSnapshot(
    id: UUID(),
    device: device,
    createdAt: Date(timeIntervalSince1970: 1),
    lastConnectedAt: lastConnectedAt
  )
  return ExtendedWAPairedDevice(device: device, record: record, isNew: isNew)
}
