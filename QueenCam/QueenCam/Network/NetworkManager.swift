//
//  NetworkManager.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation
import Network
import OSLog
import WiFiAware

actor NetworkManager: NetworkManagerProtocol {
  public let localEvents: AsyncStream<LocalEvent>
  private let localEventsContinuation: AsyncStream<LocalEvent>.Continuation

  public let networkEvents: AsyncStream<NetworkEvent>
  private let networkEventsContinuation: AsyncStream<NetworkEvent>.Continuation

  private let connectionManager: ConnectionManagerProtocol

  private let logger = QueenLogger(category: "NetworkManager")

  init(connectionManager: ConnectionManagerProtocol) {
    (self.localEvents, self.localEventsContinuation) = AsyncStream.makeStream(of: LocalEvent.self)
    (self.networkEvents, self.networkEventsContinuation) = AsyncStream.makeStream(of: NetworkEvent.self)

    self.connectionManager = connectionManager
  }

  // MARK: - NetworkListener (Publisher)

  func listen(to device: WAPairedDevice) async throws {
    logger.info("Start NetworkListener")

    try await NetworkListener(
      for:
        .wifiAware(.connecting(to: .previewService, from: .selected([device]))),
      using: .parameters {
        Coder(receiving: NetworkEvent.self, sending: NetworkEvent.self, using: NetworkJSONCoder()) {
          TCP()
        }
      }
      .wifiAware { $0.performanceMode = appPerformanceMode }
      .serviceClass(appServiceClass)
    )
    .onStateUpdate { listener, state in
      self.logger.info("listener onStateUpdate - \(String(describing: listener)): \(String(describing: state))")

      switch state {
      case .setup, .waiting: break
      case .ready: self.localEventsContinuation.yield(.listenerRunning)
      case .failed(let error): self.localEventsContinuation.yield(.listenerStopped(error.wifiAware))
      case .cancelled: self.localEventsContinuation.yield(.listenerStopped(nil))
      default: break
      }
    }
    .run { connection in
      self.logger.info("Received connection: \(String(describing: connection))")
      await self.connectionManager.add(connection)
    }
  }

  // MARK: - NetworkBrowser (Subscriber)

  func browse(for device: WAPairedDevice) async throws {
    logger.info("Start NetworkBrowser")

    let browser = NetworkBrowser(
      for:
        .wifiAware(.connecting(to: .selected([device]), from: .previewService))
    )
    .onStateUpdate { browser, state in
      self.logger.info("browser onStateUpdate - \(String(describing: browser)): \(String(describing: state))")

      switch state {
      case .setup, .waiting: break
      case .ready: self.localEventsContinuation.yield(.browserRunning)
      case .failed(let error): self.localEventsContinuation.yield(.browserStopped(error.wifiAware))
      case .cancelled: self.localEventsContinuation.yield(.browserStopped(nil))
      default: break
      }
    }

    // Connect to the first discovered endpoint.
    let endpoint = try await browser.run { [weak self] waEndpoints in
      self?.logger.info("Discovered: \(waEndpoints)")
      if let firstEndpoint = waEndpoints.first {
        return .finish(firstEndpoint)
      } else {
        return .continue
      }
    }

    logger.info("Attempting connection to: \(endpoint)")
    localEventsContinuation.yield(.connecting)
    await connectionManager.setupConnection(to: endpoint)
  }

  // MARK: - Send

  func send(_ event: NetworkEvent, to connection: WiFiAwareConnection) async {
    await connectionManager.send(event, to: connection)
  }

  func sendToAll(_ event: NetworkEvent) async {
    await connectionManager.sendToAll(event)
  }

  // MARK: - Deinit

  deinit {
    localEventsContinuation.finish()
    networkEventsContinuation.finish()
  }
}
