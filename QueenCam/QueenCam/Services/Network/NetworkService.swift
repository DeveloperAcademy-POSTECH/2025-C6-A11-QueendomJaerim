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

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "NetworkService")

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
    Task.detached {
      await self.connectionManager.stopAll()
    }
  }

  func send(for event: NetworkEvent) async {
    await self.networkManager.sendToAll(event)
  }
}
