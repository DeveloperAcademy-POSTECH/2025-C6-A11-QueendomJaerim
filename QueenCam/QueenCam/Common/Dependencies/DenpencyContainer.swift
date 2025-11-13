//
//  DenpencyContainer.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Foundation

final class DependencyContainer {
  static let defaultContainer: DependencyContainer = .init()

  lazy var connectionManager: ConnectionManagerProtocol = ConnectionManager()
  lazy var networkManager: NetworkManagerProtocol = NetworkManager(connectionManager: connectionManager)
  lazy var networkService: NetworkServiceProtocol = NetworkService(
    networkManager: networkManager,
    connectionManager: connectionManager
  )

  lazy var previewCaptureService = PreviewCaptureService()

  lazy var cameraSettingServcice: CameraSettingsServiceProtocol = CameraSettingsService()

  lazy var notificationService: NotificationService = NotificationService()

  // lazy면 NotificaitonCenter 기반 이벤트 로깅이 작동하지 않을 수 있음
  let analyticsService: AnalyticsService = AnalyticsService()
}
