//
//  NetworkServiceTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 10/13/25.
//

import Combine
import Foundation
import Network
import Testing
import WiFiAware

@testable import QueenCam

// MARK: - Mocks

final class MockNetworkManager: NetworkManagerProtocol {
  let localEvents: AsyncStream<LocalEvent>
  private let localCont: AsyncStream<LocalEvent>.Continuation

  let networkEvents: AsyncStream<NetworkEvent>
  private let networkCont: AsyncStream<NetworkEvent>.Continuation

  private(set) var listenCalledWith: WAPairedDevice?
  private(set) var browseCalledWith: WAPairedDevice?
  private(set) var sendToAllEvents: [NetworkEvent] = []
  private(set) var sendEvents: [(NetworkEvent, WiFiAwareConnection)] = []

  var listenBehavior: (@Sendable (WAPairedDevice) async throws -> Void)?
  var browseBehavior: (@Sendable (WAPairedDevice) async throws -> Void)?

  init() {
    (localEvents, localCont) = AsyncStream.makeStream(of: LocalEvent.self)
    (networkEvents, networkCont) = AsyncStream.makeStream(of: NetworkEvent.self)
  }

  func emitLocal(_ event: LocalEvent) { localCont.yield(event) }
  func emitNetwork(_ event: NetworkEvent) { networkCont.yield(event) }

  func finish() {
    localCont.finish()
    networkCont.finish()
  }

  func listen(to device: WAPairedDevice) async throws {
    listenCalledWith = device
    if let listenBehavior {
      try await listenBehavior(device)
    }
  }

  func browse(for device: WAPairedDevice) async throws {
    browseCalledWith = device
    if let browseBehavior {
      try await browseBehavior(device)
    }
  }

  func send(_ event: NetworkEvent, to connection: WiFiAwareConnection) async {
    sendEvents.append((event, connection))
  }

  func sendToAll(_ event: NetworkEvent) async {
    sendToAllEvents.append(event)
  }
}

final class MockConnectionManager: ConnectionManagerProtocol {
  let localEvents: AsyncStream<LocalEvent>
  private let localCont: AsyncStream<LocalEvent>.Continuation

  let networkEvents: AsyncStream<NetworkEvent>
  private let networkCont: AsyncStream<NetworkEvent>.Continuation

  private(set) var invalidateCalledWith: [WiFiAwareConnectionID] = []

  init() {
    (localEvents, localCont) = AsyncStream.makeStream(of: LocalEvent.self)
    (networkEvents, networkCont) = AsyncStream.makeStream(of: NetworkEvent.self)
  }

  func emitLocal(_ event: LocalEvent) { localCont.yield(event) }
  func emitNetwork(_ event: NetworkEvent) { networkCont.yield(event) }

  func add(_ connection: WiFiAwareConnection) async {}
  func setupConnection(to endpoint: WAEndpoint) async {}
  func send(_ event: NetworkEvent, to connection: WiFiAwareConnection) async {}
  func sendToAll(_ event: NetworkEvent) async {}
  func monitor() async throws {}
  func stop(_ connection: WiFiAwareConnection) async {}

  func invalidate(_ id: WiFiAwareConnectionID) async {
    invalidateCalledWith.append(id)
  }
}

// MARK: - Helpers

private func makeDummyDevice(id: String = UUID().uuidString) -> WAPairedDevice {
  WAPairedDevice.sample
}

private func makeDummyConnection(id: WiFiAwareConnectionID = UUID().uuidString) -> WiFiAwareConnection {
  // NetworkConnection을 직접 만들기 어렵다면, ConnectionDetail에 필요한 최소 항목만 비교하도록
  // 테스트를 구성하세요. 여기서는 프로토콜 타입의 메서드 인자 추적만 하고,
  // 실제 send(to:) 호출 여부만 검증합니다. 따라서 connection 자체는 사용하지 않아도 됩니다.
  fatalError("Provide a real or testable WiFiAwareConnection if needed by your tests.")
}

@Suite("NetworkService Tests")
struct NetworkServiceTests {
  @Test("mode 설정 시 초기 상태가 올바르게 설정된다")
  func initialStateOnModeSet() async throws {
    let mockNM = MockNetworkManager()
    let mockCM = MockConnectionManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: mockCM)

    var receivedStates: [NetworkState] = []
    let cancellable = service.networkStatePublisher
      .compactMap { $0 }
      .sink { receivedStates.append($0) }

    // host
    service.mode = .host
    // viewer
    service.mode = .viewer

    // 약간의 비동기 여유
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(receivedStates.contains(.host(.stopped)))
    #expect(receivedStates.contains(.viewer(.stopped)))
    _ = cancellable
  }

  @Test("run(for:)이 host면 listen, viewer면 browse를 호출한다")
  func runCallsCorrectAPI() async throws {
    let mockNM = MockNetworkManager()
    let mockCM = MockConnectionManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: mockCM)
    let device = makeDummyDevice()

    // host
    service.mode = .host
    Task.detached { service.run(for: device) }
    try await Task.sleep(nanoseconds: 50_000_000)
    #expect(mockNM.listenCalledWith != nil)
    #expect(mockNM.listenCalledWith?.id == device.id)

    // viewer
    service.stop()
    service.mode = .viewer
    Task.detached { service.run(for: device) }
    try await Task.sleep(nanoseconds: 50_000_000)
    #expect(mockNM.browseCalledWith != nil)
    #expect(mockNM.browseCalledWith?.id == device.id)
  }

  @Test("listenerRunning/browserRunning 이벤트에 따라 상태가 publishing/browsing으로 전환된다")
  func stateTransitionsOnRunningEvents() async throws {
    let mockNM = MockNetworkManager()
    let mockCM = MockConnectionManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: mockCM)

    var receivedStates: [NetworkState] = []
    let cancellable = service.networkStatePublisher.compactMap { $0 }.sink { receivedStates.append($0) }

    service.mode = .host
    mockNM.emitLocal(.listenerRunning)
    try await Task.sleep(nanoseconds: 50_000_000)
    #expect(receivedStates.contains(.host(.publishing)))

    service.mode = .viewer
    mockNM.emitLocal(.browserRunning)
    try await Task.sleep(nanoseconds: 50_000_000)
    #expect(receivedStates.contains(.viewer(.browsing)))
    _ = cancellable
  }

  @Test("connecting 이벤트에 따라 viewer 연결중 상태로 전환된다")
  func stateConnectingOnLocalConnecting() async throws {
    let mockNM = MockNetworkManager()
    let mockCM = MockConnectionManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: mockCM)

    var receivedStates: [NetworkState] = []
    let cancellable = service.networkStatePublisher.compactMap { $0 }.sink { receivedStates.append($0) }

    service.mode = .viewer
    mockNM.emitLocal(.connecting)
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(receivedStates.contains(.viewer(.connecting)))
    _ = cancellable
  }

  @Test("NetworkEvent가 전달되면 networkEventPublisher로 방출된다")
  func networkEventForwarding() async throws {
    let mockNM = MockNetworkManager()
    let mockCM = MockConnectionManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: mockCM)

    var received: [NetworkEvent] = []
    let cancellable = service.networkEventPublisher.compactMap { $0 }.sink { received.append($0) }

    let now = Date()
    mockNM.emitNetwork(.ping(now))
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(received.contains { if case .ping(let date) = $0 { return date == now } else { return false } })
    _ = cancellable
  }

  @Test("stop() 호출 시 상태가 stopped로 전환된다")
  func stopCancelsTaskAndSetsStopped() async throws {
    let mockNM = MockNetworkManager()
    let mockCM = MockConnectionManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: mockCM)
    let device = makeDummyDevice()

    var receivedStates: [NetworkState] = []
    let cancellable = service.networkStatePublisher.compactMap { $0 }.sink { receivedStates.append($0) }

    service.mode = .viewer

    // run 시작
    Task.detached { service.run(for: device) }
    try await Task.sleep(nanoseconds: 50_000_000)

    // stop
    service.stop()
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(receivedStates.contains(.viewer(.stopped)))
    _ = cancellable
  }

  @Test("send(for:)는 sendToAll을 호출한다")
  func sendForwardsToSendToAll() async throws {
    let mockNM = MockNetworkManager()
    let mockCM = MockConnectionManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: mockCM)

    let event = NetworkEvent.ping(Date())
    await service.send(for: event)

    #expect(mockNM.sendToAllEvents.count == 1)
  }
}

// 테스트 및 미리보기 전용 데이터를 관리하기 위한 확장
extension WAPairedDevice {
  /// SwiftUI 미리보기 또는 테스트에서 사용할 수 있는 단일 샘플 데이터입니다.
  static var sample: WAPairedDevice {
    let jsonString = """
      {
          "id": 1001,
          "name": "안방 조명",
          "pairingInfo": {
              "pairingName": "Smart Lamp 2",
              "vendorName": "스마트홈",
              "modelName": "LightBright v2"
          }
      }
      """
    let jsonData = jsonString.data(using: .utf8)!
    return try! JSONDecoder().decode(WAPairedDevice.self, from: jsonData)
  }
}
