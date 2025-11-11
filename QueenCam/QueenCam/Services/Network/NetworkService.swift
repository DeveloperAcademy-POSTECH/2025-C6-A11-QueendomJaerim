//
//  NetworkService.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Combine
import Foundation
import OSLog
import WiFiAware

final class NetworkService: NetworkServiceProtocol {
  // MARK: Published properties isolated to MainActor
  /// Wi-Fi Aware mode
  var mode: NetworkType? {
    didSet {
      logger.debug("network mode updated: \(self.mode.debugDescription)")
      self.networkState = mode == .host ? .host(.stopped) : .viewer(.stopped)
    }
  }

  /// Available connections
  private let deviceConnectionsSubject = CurrentValueSubject<[WAPairedDevice: ConnectionDetail], Never>([:])
  var deviceConnectionsPublisher: AnyPublisher<[WAPairedDevice: ConnectionDetail], Never> {
    deviceConnectionsSubject.eraseToAnyPublisher()
  }
  private var deviceConnections: [WAPairedDevice: ConnectionDetail] = [:] {
    didSet {
      logger.debug("device connections updated: \(self.deviceConnections)")
      deviceConnectionsSubject.send(deviceConnections)
    }
  }

  /// Last error
  private let lastErrorSubject = CurrentValueSubject<Error?, Never>(nil)
  var lastErrorPublisher: AnyPublisher<Error?, Never> {
    lastErrorSubject.eraseToAnyPublisher()
  }

  // MARK: Published subjects
  /// Network state
  private let networkStateSubject = CurrentValueSubject<NetworkState?, Never>(nil)
  var networkStatePublisher: AnyPublisher<NetworkState?, Never> {
    networkStateSubject.eraseToAnyPublisher()
  }
  private(set) var networkState: NetworkState? {
    didSet {
      logger.debug("network state updated: \(self.networkState?.debugDescription ?? "")")

      networkStateSubject.send(networkState)

      // 연결이 취소되거나 유실되었다면 헬스 체크를 리셋한다
      if networkState == .host(.cancelled)
          || networkState == .viewer(.cancelled)
          || networkState == .host(.lost)
          || networkState == .viewer(.lost) {
        resetHealthCheck()  // 헬스 체크 리셋
      }
      
      // 연결이 취소되었다면 다음 태스크에서 stopped 상태로 전환한다
      // 유실된 경우 추가적인 액션을 필요로 한다. 따라서 바로 stopped 상태로 전환하지 않는다.
      if networkState == .host(.cancelled)
          || networkState == .viewer(.cancelled) {
        Task {
          networkState = mode == .host ? .host(.stopped) : .viewer(.stopped)
        }
      }

      // 연결이 stopped 상태일 때 networkTask가 진행중이면 취소한다
      if networkState != .host(.stopped) && networkState != .viewer(.stopped) {
        return
      }
      if let networkTask, !networkTask.isCancelled {
        networkTask.cancel()
        logger.warning("networkState가 stopped으로 전환되었으나 networkTask가 유효하여 취소하였습니다")
      }
    }
  }

  /// Network event
  private let networkEventSubject = CurrentValueSubject<NetworkEvent?, Never>(nil)
  var networkEventPublisher: AnyPublisher<NetworkEvent?, Never> {
    networkEventSubject.eraseToAnyPublisher()
  }

  private var networkTask: Task<Void, Error>?
  private let networkManager: NetworkManagerProtocol
  private let connectionManager: ConnectionManagerProtocol
  private var eventHandlerTasks: [Task<Void, Error>] = []

  // Monitoring
  private var monitorTimer: Timer?
  private let monitoringInterval: TimeInterval = 0.5
  private var deviceReports: [WAPairedDevice: WAPerformanceReport] = [:] {
    didSet {
      deviceReportsSubject.send(deviceReports)
    }
  }
  private let deviceReportsSubject = CurrentValueSubject<[WAPairedDevice: WAPerformanceReport], Never>([:])
  var deviceReportsPublisher: AnyPublisher<[WAPairedDevice: WAPerformanceReport], Never> {
    deviceReportsSubject.eraseToAnyPublisher()
  }

  // Health Check
  private let healthCheckPeriod: TimeInterval = 0.5
  private var healthCheckTimer: Timer?
  private var requestedRandomCode: String?
  private var healthCheckPending: Bool = false  // 현재 요청한 헬스 체크 응답이 도착하지 않으면 true, 도착했으면 false
  private var lastHealthCheckTime: Date?

  // Reconnection
  @MainActor private var isReconnecting: Bool = false

  private let logger = QueenLogger(category: "NetworkService")

  init() {
    let connectionManager = ConnectionManager()
    let networkManager = NetworkManager(connectionManager: connectionManager)
    self.connectionManager = connectionManager
    self.networkManager = networkManager

    eventHandlerTasks.append(setupEventHandler(for: networkManager.localEvents))
    eventHandlerTasks.append(setupEventHandler(for: networkManager.networkEvents))
    eventHandlerTasks.append(setupEventHandler(for: connectionManager.localEvents))
    eventHandlerTasks.append(setupEventHandler(for: connectionManager.networkEvents))
  }

  init(networkManager: NetworkManagerProtocol, connectionManager: ConnectionManagerProtocol) {
    self.networkManager = networkManager
    self.connectionManager = connectionManager

    eventHandlerTasks.append(setupEventHandler(for: networkManager.localEvents))
    eventHandlerTasks.append(setupEventHandler(for: networkManager.networkEvents))
    eventHandlerTasks.append(setupEventHandler(for: connectionManager.localEvents))
    eventHandlerTasks.append(setupEventHandler(for: connectionManager.networkEvents))
  }
}

extension NetworkService {
  // MARK: - Event Handling

  private func setupEventHandler<T>(for stream: AsyncStream<T>) -> Task<Void, Error> {
    Task {
      for await event in stream {
        if T.self == LocalEvent.self {
          await handleLocalEvent(event as? LocalEvent)
        } else if T.self == NetworkEvent.self {
          await handleNetworkEvent(event as? NetworkEvent)
        }
      }
    }
  }

  private func handleLocalEvent(_ event: LocalEvent?) async {
    guard let event else { return }

    logger.debug("handleLocalEvent - \(String(describing: event))")

    switch event {
    case .listenerRunning, .browserRunning:
      networkState = mode == .host ? .host(.publishing) : .viewer(.browsing)

    case .connecting:
      networkState = .viewer(.connecting)

    case .browserStopped(let error), .listenerStopped(let error):
      networkState = mode == .host ? .host(.stopped) : .viewer(.stopped)

      if let waError = error {
        logger.error("browserStopped 또는 listenerStopped 상태에서 에러가 발생했습니다. \(waError.localizedDescription)")
        lastErrorSubject.send(waError)

        if case .serviceAlreadyPublishing = waError {
          logger.debug("The error was .serviceAlreadyPublishing, so do nothing.")
          return
        }
        
        if case .serviceAlreadySubscribing = waError {
          logger.debug("The error was .serviceAlreadySubscribing, so do nothing.")
          return
        }

        if mode == .viewer {
          networkState = .viewer(.lost)
        } else {
          networkState = .host(.lost)
        }
      }

    case .connection(let conectionEvent):
      await handleConnectionEvent(conectionEvent)
    }
  }

  private func handleConnectionEvent(_ event: LocalEvent.ConnectionEvent) async {
    logger.debug("handleConnectionEvent - \(String(describing: event))")

    switch event {
    case .ready(let device, let connectionDetail):
      deviceConnections[device] = connectionDetail
      if mode == .viewer {
        networkTask?.cancel()
        networkTask = nil

        await networkManager.send(.startSession, to: connectionDetail.connection)  // Wake-up message
        networkState = .viewer(.connected)

        // 헬스체크 타이머 시작 (viewer)
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: healthCheckPeriod, repeats: true) { [weak self] _ in
          self?.handleTimer()
        }
      } else {
        networkState = .host(.publishing)
      }

    case .performance(let device, let connectionDetail):
      deviceReports[device] = connectionDetail.performanceReport

    case .stopped(let device, let connectionID, let error):
      logger.info("handle stopped event \(error)")
      deviceConnections.removeValue(forKey: device)
      await connectionManager.invalidate(connectionID)

      if let waError = error {
        logger.error("stopped 상태에서 에러가 발생했습니다. \(waError.localizedDescription)")
        lastErrorSubject.send(waError)

        if mode == .viewer {
          networkState = .viewer(.lost)
        } else {
          networkState = .host(.lost)
        }
      }
    }
  }

  private func handleNetworkEvent(_ event: NetworkEvent?) async {
    guard let event else { return }

    if case .previewFrame = event {
      // Skip logging for preview frames
    } else {
      logger.debug("handleNetworkEvent - \(String(describing: event))")  // preview frame 이벤트가 아닐 때만 로깅
    }

    if case .healthCheckRequest(let randomCode) = event {
      handleHealthCheckRequestEvent(code: randomCode)
    }

    if case .healthCheckResponse(let randomCode) = event {
      handleHealthCheckResponseEvent(code: randomCode)
    }

    if case .willDisconnect = event {
      logger.info("Received willDisconnect event. Stopping connection.")
      stop(byUser: true)
    }

    networkEventSubject.send(event)
  }

  private func startMonitoring(interval: TimeInterval) {
    monitorTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
      Task { [weak self] in
        try await self?.connectionManager.monitor()
      }
    }
  }

  private func stopMonitoring() {
    monitorTimer?.invalidate()
    monitorTimer = nil
  }
}

extension NetworkService {
  // MARK: - Public Interfaces

  func run(for device: WAPairedDevice) {
    logger.debug("run() invoked")

    networkTask = Task {
      _ = try await withTaskCancellationHandler {
        try await mode == .host ? networkManager.listen(to: device) : networkManager.browse(for: device)
      } onCancel: {
        Task { @MainActor in
          networkState = mode == .host ? .host(.stopped) : .viewer(.stopped)
        }
      }
    }

    startMonitoring(interval: monitoringInterval)
  }

  func disconnect() {
    Task {
      await send(for: .willDisconnect)
      try? await Task.sleep(for: .milliseconds(100))  // 상대가 연결 중단 이벤트를 처리할 수 있도록 조금 기다린다
      stop(byUser: true)
    }
  }

  func reconnect(for device: WAPairedDevice) {
    Task { @MainActor in
      guard !isReconnecting else {
        logger.warning("Reconnect already in progress. Ignoring new request.")
        return
      }

      isReconnecting = true

      networkTask?.cancel()

      await self.connectionManager.stopAll()

      networkTask = Task {
        _ = try await withTaskCancellationHandler {
          try await mode == .host ? networkManager.listen(to: device) : networkManager.browse(for: device)
        } onCancel: {
          Task { @MainActor in
            networkState = mode == .host ? .host(.stopped) : .viewer(.stopped)
          }
        }
      }

      isReconnecting = false
    }

    networkTask?.cancel()

    Task {
      await self.connectionManager.stopAll()

      networkTask = Task {
        _ = try await withTaskCancellationHandler {
          try await mode == .host ? networkManager.listen(to: device) : networkManager.browse(for: device)
        } onCancel: {
          Task { @MainActor in
            networkState = mode == .host ? .host(.stopped) : .viewer(.stopped)
          }
        }
      }
    }
  }

  func stop(byUser: Bool) {
    stopMonitoring()
    networkTask?.cancel()
    Task {
      await self.connectionManager.stopAll()

      if byUser {
        self.networkState = self.mode == .host ? .host(.cancelled) : .viewer(.cancelled)
      } else {
        self.networkState = self.mode == .host ? .host(.lost) : .viewer(.lost)
      }
    }
  }

  func send(for event: NetworkEvent) async {
    await self.networkManager.sendToAll(event)
  }
}

// MARK: Health Check
extension NetworkService {
  private var codeLength: Int {
    12
  }

  /// 연결이 끊겼다고 판정할 헬스 체크 시간
  private var healthCheckTimeout: TimeInterval {
    2.0
  }

  /// 헬스 체크 프로토콜 시작 (뷰어)
  private func requestHealthCheck() {
    healthCheckPending = true

    let randomCode = RandomGenerator.string(length: codeLength)
    requestedRandomCode = randomCode

    Task {
      await send(for: .healthCheckRequest(randomCode))
    }
  }

  /// 헬스 체크 타이머가 실행할 메서드
  private func handleTimer() {
    if !healthCheckPending {  // 현재 요청해둔 헬스 체크가 있으면 건너 뛴다
      requestHealthCheck()
      // logger.debug("Requested health check")
    } else {
      logger.warning("health check skipped. still pending.")
    }

    if let lastHealthCheckTime {  // 타임 아웃 확인
      if Date().timeIntervalSince(lastHealthCheckTime) > healthCheckTimeout {
        logger.warning("Health Check Timeout. Cancelling connection")
        stop(byUser: false)
      } else {
        // logger.debug("Health okay")
      }
    }
  }

  /// 헬스 체크 요청 메시지 핸들링 (호스트가 받음)
  private func handleHealthCheckRequestEvent(code: String) {
    Task {
      if self.networkState == .host(.publishing) || self.networkState == .viewer(.connected) {
        await send(for: .healthCheckResponse(code))
      } else {
        logger.warning("health check ignored because connection lost or stopped.")
      }
    }
  }

  /// 헬스 체크 응답 메시지 핸들링 (뷰어가 받음)
  private func handleHealthCheckResponseEvent(code: String) {
    if requestedRandomCode == code {
      // logger.debug("Exchange code success. health check ok")
      lastHealthCheckTime = Date()
      requestedRandomCode = nil
      healthCheckPending = false
    } else {
      logger.error("Exchange code does not match. connection will be cancelled.")
      networkState = .viewer(.cancelled)
    }
  }

  /// 헬스 체크 리셋
  private func resetHealthCheck() {
    healthCheckTimer?.invalidate()
    healthCheckTimer = nil
    lastHealthCheckTime = nil
    healthCheckPending = false
  }
}
