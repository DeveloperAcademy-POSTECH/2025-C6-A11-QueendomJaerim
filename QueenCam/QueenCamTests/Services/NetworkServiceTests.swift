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
  func stopAll() {}

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
    service.stop(byUser: true)
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
    service.stop(byUser: true)
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

  @Test("연결 전에는 상대 버전 확인 통과 신호가 꺼져 있다")
  func counterpartVersionNotVerifiedInitially() {
    let service = NetworkService(networkManager: MockNetworkManager(), connectionManager: MockConnectionManager())

    #expect(service.isCounterpartVersionVerified == false)
  }

  @Test("호환되는 버전을 받으면 통과 신호가 켜진다")
  func compatibleVersionVerifiesCounterpart() async throws {
    let mockNM = MockNetworkManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: MockConnectionManager())

    let payload = VersionExchangePayload(version: VersionUtils.currentVersion, requiredMinimumVersion: 0)
    mockNM.emitNetwork(.myVersion(payload))
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(service.isCounterpartVersionVerified)
  }

  @Test("상대 앱 버전이 최소 호환 버전보다 낮으면 통과 신호가 켜지지 않는다")
  func outdatedCounterpartIsNotVerified() async throws {
    let mockNM = MockNetworkManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: MockConnectionManager())

    let payload = VersionExchangePayload(version: 0, requiredMinimumVersion: 0)
    mockNM.emitNetwork(.myVersion(payload))
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(service.isCounterpartVersionVerified == false)
  }

  @Test("내 앱 버전이 상대가 요구하는 최소 버전보다 낮으면 통과 신호가 켜지지 않는다")
  func outdatedMyAppIsNotVerified() async throws {
    let mockNM = MockNetworkManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: MockConnectionManager())

    let payload = VersionExchangePayload(version: VersionUtils.currentVersion, requiredMinimumVersion: Int.max)
    mockNM.emitNetwork(.myVersion(payload))
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(service.isCounterpartVersionVerified == false)
  }

  @Test("stop()을 호출하면 통과 신호가 꺼진다")
  func stopResetsVerification() async throws {
    let mockNM = MockNetworkManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: MockConnectionManager())

    mockNM.emitNetwork(.myVersion(VersionExchangePayload(version: VersionUtils.currentVersion, requiredMinimumVersion: 0)))
    try await Task.sleep(nanoseconds: 50_000_000)
    #expect(service.isCounterpartVersionVerified)

    service.stop(byUser: true)

    #expect(service.isCounterpartVersionVerified == false)
  }

  @Test("run(for:)로 새 연결을 시작하면 통과 신호가 꺼진다")
  func runResetsVerification() async throws {
    let mockNM = MockNetworkManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: MockConnectionManager())

    mockNM.emitNetwork(.myVersion(VersionExchangePayload(version: VersionUtils.currentVersion, requiredMinimumVersion: 0)))
    try await Task.sleep(nanoseconds: 50_000_000)
    #expect(service.isCounterpartVersionVerified)

    service.mode = .host
    service.run(for: makeDummyDevice())

    #expect(service.isCounterpartVersionVerified == false)
  }

  @Test("reconnect(for:)로 다시 연결하면 통과 신호가 꺼진다")
  func reconnectResetsVerification() async throws {
    let mockNM = MockNetworkManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: MockConnectionManager())

    mockNM.emitNetwork(.myVersion(VersionExchangePayload(version: VersionUtils.currentVersion, requiredMinimumVersion: 0)))
    try await Task.sleep(nanoseconds: 50_000_000)
    #expect(service.isCounterpartVersionVerified)

    service.mode = .host
    service.reconnect(for: makeDummyDevice())
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(service.isCounterpartVersionVerified == false)
  }

  @Test("stop()을 호출하면 버전 확인 알람이 꺼진다")
  func stopInvalidatesVersionCheckTimer() {
    let service = NetworkService(networkManager: MockNetworkManager(), connectionManager: MockConnectionManager())
    let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in }
    service.versionCheckTimer = timer

    service.stop(byUser: true)

    #expect(timer.isValid == false)
    #expect(service.versionCheckTimer == nil)
  }

  @Test("run(for:)으로 새 연결을 시작하면 이전 버전 확인 알람이 꺼진다")
  func runInvalidatesVersionCheckTimer() {
    let service = NetworkService(networkManager: MockNetworkManager(), connectionManager: MockConnectionManager())
    let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in }
    service.versionCheckTimer = timer

    service.mode = .host
    service.run(for: makeDummyDevice())

    #expect(timer.isValid == false)
    #expect(service.versionCheckTimer == nil)
  }

  @Test("다시 연결하면 이전 연결의 버전 확인 알람이 울리지 않는다")
  @MainActor
  func reconnectSilencesPreviousVersionCheckTimer() async throws {
    let service = NetworkService(networkManager: MockNetworkManager(), connectionManager: MockConnectionManager())
    let previousAlarm = TimerFireRecorder()
    let controlAlarm = TimerFireRecorder()
    service.versionCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in previousAlarm.fired = true }
    let controlTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in controlAlarm.fired = true }

    service.mode = .host
    service.reconnect(for: makeDummyDevice())
    try await Task.sleep(nanoseconds: 300_000_000)

    // 같은 시간의 다른 알람은 울려야, 이전 알람이 울리지 않은 것을 믿을 수 있다.
    #expect(controlAlarm.fired)
    #expect(previousAlarm.fired == false)
    controlTimer.invalidate()
  }

  @Test("연결 하나가 끝나면 통과 표시와 버전 확인 알람이 지워진다")
  func stoppedConnectionResetsVersionCheck() async throws {
    let mockNM = MockNetworkManager()
    let mockCM = MockConnectionManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: mockCM)

    mockNM.emitNetwork(.myVersion(VersionExchangePayload(version: VersionUtils.currentVersion, requiredMinimumVersion: 0)))
    try await Task.sleep(nanoseconds: 50_000_000)
    #expect(service.isCounterpartVersionVerified)
    let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in }
    service.versionCheckTimer = timer
    service.currentConnectionID = "connection-1"

    mockCM.emitLocal(.connection(.stopped(makeDummyDevice(), "connection-1", nil)))
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(service.isCounterpartVersionVerified == false)
    #expect(timer.isValid == false)
    #expect(service.currentConnectionID == nil)
  }

  @Test("지금 연결이 아닌 이전 연결의 종료 신호는 통과 표시와 버전 확인 알람을 지우지 않는다")
  func stoppedPreviousConnectionKeepsVersionCheck() async throws {
    let mockNM = MockNetworkManager()
    let mockCM = MockConnectionManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: mockCM)

    mockNM.emitNetwork(.myVersion(VersionExchangePayload(version: VersionUtils.currentVersion, requiredMinimumVersion: 0)))
    try await Task.sleep(nanoseconds: 50_000_000)
    #expect(service.isCounterpartVersionVerified)
    let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in }
    service.versionCheckTimer = timer
    service.currentConnectionID = "connection-2"

    mockCM.emitLocal(.connection(.stopped(makeDummyDevice(), "connection-1", nil)))
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(service.isCounterpartVersionVerified)
    #expect(timer.isValid)
    #expect(service.currentConnectionID == "connection-2")
    #expect(mockCM.invalidateCalledWith == ["connection-1"])
    timer.invalidate()
  }

  @Test("비율 동기화 이벤트는 실제 전송 형식(JSON)으로 보내고 다시 읽을 수 있다")
  func aspectRatioEventsSurviveJSONRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let request = try decoder.decode(NetworkEvent.self, from: encoder.encode(NetworkEvent.requestPhotoAspectRatio))
    let ratio = try decoder.decode(NetworkEvent.self, from: encoder.encode(NetworkEvent.photoAspectRatio(.ratio16x9)))

    guard case .requestPhotoAspectRatio = request else {
      Issue.record("요청 이벤트를 읽지 못했습니다: \(request)")
      return
    }
    guard case .photoAspectRatio(.ratio16x9) = ratio else {
      Issue.record("비율 이벤트를 읽지 못했습니다: \(ratio)")
      return
    }
  }

  @Test("버전을 확인하기 전에 알람이 울리면 연결을 끊고 안내를 남긴다")
  func versionCheckTimeoutStopsBeforeVerification() {
    let service = NetworkService(networkManager: MockNetworkManager(), connectionManager: MockConnectionManager())

    service.handleVersionCheckTimer()

    #expect(service.lastStopReason?.contains("친구 앱의 버전을 확인할 수 없습니다") == true)
  }

  @Test("버전 확인을 통과한 뒤 알람이 울리면 연결을 유지한다")
  func versionCheckTimeoutKeepsVerifiedConnection() async throws {
    let mockNM = MockNetworkManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: MockConnectionManager())

    mockNM.emitNetwork(.myVersion(VersionExchangePayload(version: VersionUtils.currentVersion, requiredMinimumVersion: 0)))
    try await Task.sleep(nanoseconds: 50_000_000)
    service.handleVersionCheckTimer()

    #expect(service.lastStopReason == nil)
    #expect(service.isCounterpartVersionVerified)
  }

  @Test("상대 버전이 낮아 연결을 끊으면 알람도 꺼져 안내가 바뀌지 않는다")
  func outdatedVersionStopsVersionCheckTimer() async throws {
    let mockNM = MockNetworkManager()
    let service = NetworkService(networkManager: mockNM, connectionManager: MockConnectionManager())
    let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in }
    service.versionCheckTimer = timer

    mockNM.emitNetwork(.myVersion(VersionExchangePayload(version: 0, requiredMinimumVersion: 0)))
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(timer.isValid == false)
    #expect(service.lastStopReason?.contains("친구 앱의 버전이 낮아서") == true)
  }
}

private final class TimerFireRecorder: @unchecked Sendable {
  var fired = false
}

// 테스트 및 미리보기 전용 데이터를 관리하기 위한 확장
extension WAPairedDevice {
  /// SwiftUI 미리보기 또는 테스트에서 사용할 수 있는 단일 샘플 데이터입니다.
  static var sample: WAPairedDevice {
    let jsonString =
      """
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
