//
//  DenpencyContainer.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Foundation

// FIXME: Temporary DI Implementation
final class DependencyContainer {
  static let defaultContainer: DependencyContainer = .init()

  lazy var connectionManager: ConnectionManagerProtocol = ConnectionManager()
  lazy var networkManager: NetworkManagerProtocol = NetworkManager(connectionManager: connectionManager)
  lazy var networkService: NetworkServiceProtocol = NetworkService(
    networkManager: networkManager,
    connectionManager: connectionManager
  )

  lazy var previewCaptureService = PreviewCaptureService()
}
