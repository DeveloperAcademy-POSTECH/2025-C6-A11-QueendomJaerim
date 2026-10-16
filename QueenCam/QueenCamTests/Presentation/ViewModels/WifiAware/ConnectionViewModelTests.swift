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

  @Test("역할을 초기화하면 연결 시도와 선택 기기를 정리한다")
  func resettingRoleStopsConnectionAndClearsSelectedDevice() async throws {
    let networkService = FakeNetworkService()
    let viewModel = ConnectionViewModel(
      networkService: networkService,
      notificationService: FakeNotificationService(),
      pairedDeviceRegistry: FakePairedDeviceRegistry(devices: AsyncStream { _ in })
    )
    let device = makeExtendedDevice(id: 1001, pairingName: "테스트 기기").device

    viewModel.selectRole(for: .photographer)
    viewModel.connectButtonDidTap(for: device)
    try await Task.sleep(for: .milliseconds(150))

    #expect(viewModel.selectedPairedDevice == device)
    let stopCallCountBeforeReset = networkService.stopCallCount

    viewModel.selectRole(for: nil)

    #expect(viewModel.role == nil)
    #expect(viewModel.selectedPairedDevice == nil)
    #expect(networkService.stopCallCount == stopCallCountBeforeReset + 1)
  }
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
  private(set) var stopCallCount = 0

  var deviceConnectionsPublisher: AnyPublisher<[WAPairedDevice: ConnectionDetail], Never> {
    Empty().eraseToAnyPublisher()
  }

  var lastErrorPublisher: AnyPublisher<Error?, Never> {
    Empty().eraseToAnyPublisher()
  }

  var networkStatePublisher: AnyPublisher<NetworkState?, Never> {
    Empty().eraseToAnyPublisher()
  }

  var networkEventPublisher: AnyPublisher<NetworkEvent?, Never> {
    Empty().eraseToAnyPublisher()
  }

  var deviceReportsPublisher: AnyPublisher<[WAPairedDevice: WAPerformanceReport], Never> {
    Empty().eraseToAnyPublisher()
  }

  func run(for device: WAPairedDevice) {}
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
    await Task.yield()
  }
  return false
}

private func makeExtendedDevice(id: UInt64, pairingName: String) -> ExtendedWAPairedDevice {
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
    lastConnectedAt: nil
  )
  return ExtendedWAPairedDevice(device: device, record: record, isNew: true)
}
