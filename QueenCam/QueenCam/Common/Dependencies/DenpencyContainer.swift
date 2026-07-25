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
  lazy var guidingStrokeRepository: GuidingStrokeRepositoryProtocol = GuidingStrokeRepository(
    networkService: networkService
  )
  lazy var previewCaptureService = PreviewCaptureService()
  lazy var cameraSettingServcice: CameraSettingsServiceProtocol = CameraSettingsService()
  lazy var notificationService = NotificationService()
  lazy var onboardingSettingService: OnboardingSettingsServiceProtocol = OnboardingSettingsService()

  private lazy var analyticsScreenContext = AnalyticsScreenContext()
  private lazy var analyticsSettingsContext = AnalyticsSettingsContext(
    cameraSettingsService: cameraSettingServcice
  )
  private lazy var analyticsService = AnalyticsService(
    screenContext: analyticsScreenContext,
    settingsContext: analyticsSettingsContext
  )
  private lazy var globalDeviceEventObserver = GlobalDeviceEventObserver()

  func bootstrap() {
    _ = analyticsService
    _ = globalDeviceEventObserver
  }
}
