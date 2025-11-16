//
//  ConnectionManager.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation
import Network
import OSLog
import WiFiAware

private struct ConnectionInfo {
  let receiverTask: Task<Void, Error>
  let stateUpdateTask: Task<Void, Error>
  var remoteDevice: WAPairedDevice?
}

actor ConnectionManager: ConnectionManagerProtocol {
  private(set) var connections: [WiFiAwareConnectionID: WiFiAwareConnection] = [:]
  private var connectionsInfo: [WiFiAwareConnectionID: ConnectionInfo] = [:]

  public let localEvents: AsyncStream<LocalEvent>
  private let localEventsContinuation: AsyncStream<LocalEvent>.Continuation

  public let networkEvents: AsyncStream<NetworkEvent>
  private let networkEventsContinuation: AsyncStream<NetworkEvent>.Continuation

  private let logger = QueenLogger(category: "ConnectionManager")

  init() {
    (self.localEvents, self.localEventsContinuation) = AsyncStream.makeStream(of: LocalEvent.self)
    (self.networkEvents, self.networkEventsContinuation) = AsyncStream.makeStream(of: NetworkEvent.self)
  }

  // MARK: - Setup

  func add(_ connection: WiFiAwareConnection) {
    logger.info("Add connection: \(connection.debugDescription)")

    connectionsInfo[connection.id] = .init(
      receiverTask: setupReceiver(connection),
      stateUpdateTask: setupStateUpdateHandler(connection)
    )
  }

  func setupConnection(to endpoint: WAEndpoint) {
    let connection = NetworkConnection(
      to:
        endpoint,
      using: .parameters {
        Coder(receiving: NetworkEvent.self, sending: NetworkEvent.self, using: NetworkJSONCoder()) {
          TCP()
        }
      }
      .wifiAware { $0.performanceMode = appPerformanceMode }
      .serviceClass(appServiceClass)
    )

    logger.info("Set up connection: \(connection.debugDescription)\nto: \(endpoint)")

    add(connection)
  }

  // MARK: - State Updates

  private func setupStateUpdateHandler(_ connection: WiFiAwareConnection) -> Task<Void, Error> {
    let (stream, continuation) = AsyncStream.makeStream(of: WiFiAwareConnectionState.self)

    connection.onStateUpdate { [weak self] connection, state in
      self?.logger.info("connection onStateUpdate - \(connection.debugDescription): \(String(describing: state))")
      continuation.yield((connection, state))
    }

    return Task {
      for await (connection, state) in stream {
        var connectionError: NWError?

        switch state {
        case .setup, .waiting, .preparing: break

        case .ready:
          connections[connection.id] = connection

          if let wifiAwarePath = try await connection.currentPath?.wifiAware {
            let connectedDevice = wifiAwarePath.endpoint.device
            let performanceReport = wifiAwarePath.performance

            let detail = ConnectionDetail(connection: connection, performanceReport: performanceReport)
            localEventsContinuation.yield(.connection(.ready(connectedDevice, detail)))

            connectionsInfo[connection.id]?.remoteDevice = connectedDevice
          }

        case .failed(let error):
          stop(connection)
          connectionError = error
          fallthrough

        case .cancelled:
          guard let disconnectedDevice = connectionsInfo[connection.id]?.remoteDevice else { continue }
          localEventsContinuation.yield(.connection(.stopped(disconnectedDevice, connection.id, connectionError?.wifiAware)))

        @unknown default: break
        }
      }
    }
  }

  // MARK: - Receive

  private func setupReceiver(_ connection: WiFiAwareConnection) -> Task<Void, Error> {
    logger.info("Set up receiver: \(connection.debugDescription)")

    return Task {
      for try await (event, _) in connection.messages {
        networkEventsContinuation.yield(event)
      }
    }
  }

  // MARK: - Send

  func send(_ event: NetworkEvent, to connection: WiFiAwareConnection) async {
    do {
      try await connection.send(event)
    } catch {
      logger.error("Failed to send to: \(connection.debugDescription): \(error)")
    }
  }

  func sendToAll(_ event: NetworkEvent) async {
    for connection in connections.values {
      await send(event, to: connection)
    }
  }

  // MARK: - Monitor

  func monitor() async throws {
    for connection in connections.values.filter({ $0.state == .ready }) {
      if let wifiAwarePath = try await connection.currentPath?.wifiAware {
        let device = wifiAwarePath.endpoint.device
        let performanceReport = wifiAwarePath.performance

        let detail = ConnectionDetail(connection: connection, performanceReport: performanceReport)
        localEventsContinuation.yield(.connection(.performance(device, detail)))
      }
    }
  }

  // MARK: - Teardown

  func stop(_ connection: WiFiAwareConnection) {
    logger.info("Stop connection: \(connection.debugDescription)")
    connectionsInfo[connection.id]?.receiverTask.cancel()
    if let removedConnection = connections.removeValue(forKey: connection.id) {
      logger.info("Removed: \(removedConnection.debugDescription)")
    }
  }

  func stopAll() {
    for (connectionId, info) in connectionsInfo {
      info.receiverTask.cancel()
      info.stateUpdateTask.cancel()

      if let device = info.remoteDevice {
        localEventsContinuation.yield(.connection(.stopped(device, connectionId, nil)))
      }
    }

    connections.removeAll()
  }

  func invalidate(_ id: WiFiAwareConnectionID) {
    logger.info("Invalidate connection ID: \(id)")
    connectionsInfo[id]?.stateUpdateTask.cancel()
    connectionsInfo.removeValue(forKey: id)
  }

  isolated deinit {
    stopAll()

    localEventsContinuation.finish()
    networkEventsContinuation.finish()
  }
}
