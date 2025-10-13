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

protocol NetworkServiceProtocol: AnyObject {
  // MARK: - Settable Properties
  /// 네트워크 모드 (호스트 / 뷰어)
  var mode: NetworkType? { get set }

  // MARK: - Observable Properties
  /// 연결 가능한 기기 목록을 방출하는 퍼블리셔입니다.
  var deviceConnectionsPublisher: AnyPublisher<[WAPairedDevice: ConnectionDetail], Never> { get }

  /// 마지막으로 발생한 에러를 방출하는 퍼블리셔입니다.
  var lastErrorPublisher: AnyPublisher<Error?, Never> { get }

  /// 현재 네트워크 상태를 방출하는 퍼블리셔입니다.
  var networkStatePublisher: AnyPublisher<NetworkState?, Never> { get }

  /// 수신된 네트워크 이벤트를 방출하는 퍼블리셔입니다.
  var networkEventPublisher: AnyPublisher<NetworkEvent?, Never> { get }

  // MARK: - Methods
  /// 네트워크 서비스를 시작합니다.
  func run(for device: WAPairedDevice)

  /// 네트워크 서비스를 중지합니다.
  func stop()
}

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
  private let deviceConnectionsSubject = PassthroughSubject<[WAPairedDevice: ConnectionDetail], Never>()
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
  private let lastErrorSubject = PassthroughSubject<Error?, Never>()
  var lastErrorPublisher: AnyPublisher<Error?, Never> {
    lastErrorSubject.eraseToAnyPublisher()
  }

  // MARK: Published subjects
  /// Network state
  private let networkStateSubject = PassthroughSubject<NetworkState?, Never>()
  var networkStatePublisher: AnyPublisher<NetworkState?, Never> {
    networkStateSubject.eraseToAnyPublisher()
  }
  private(set) var networkState: NetworkState? {
    didSet {
      logger.debug("network state updated: \(self.networkState?.debugDescription ?? "")")

      networkStateSubject.send(networkState)

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
  private let networkEventSubject = PassthroughSubject<NetworkEvent?, Never>()
  var networkEventPublisher: AnyPublisher<NetworkEvent?, Never> {
    networkEventSubject.eraseToAnyPublisher()
  }

  private var networkTask: Task<Void, Error>?
  private let networkManager: NetworkManager
  private let connectionManager: ConnectionManager
  private var eventHandlerTasks: [Task<Void, Error>] = []

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "NetworkService")

  init() {
    self.connectionManager = ConnectionManager()
    self.networkManager = NetworkManager(connectionManager: self.connectionManager)

    eventHandlerTasks.append(setupEventHandler(for: networkManager.localEvents))
    eventHandlerTasks.append(setupEventHandler(for: networkManager.networkEvents))
    eventHandlerTasks.append(setupEventHandler(for: connectionManager.localEvents))
    eventHandlerTasks.append(setupEventHandler(for: connectionManager.networkEvents))
  }

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

        await networkManager.send(.startStreaming, to: connectionDetail.connection)  // Wake-up message
        networkState = .viewer(.connected)
      }
    case .performance(let device, let connectionDetail):
      deviceConnections[device] = connectionDetail

    case .stopped(let device, let connectionID, let error):
      deviceConnections.removeValue(forKey: device)
      await connectionManager.invalidate(connectionID)

      if mode == .viewer {
        networkState = .viewer(.stopped)
      }

      if let waError = error {
        logger.error("stopped 상태에서 에러가 발생했습니다. \(waError.localizedDescription)")
        lastErrorSubject.send(waError)
      }
    }
  }

  private func handleNetworkEvent(_ event: NetworkEvent?) async {
    guard let event else { return }

    logger.debug("handleNetworkEvent - \(String(describing: event))")

    networkEventSubject.send(event)
  }

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
  }

  func stop() {
    networkTask?.cancel()
  }
}
