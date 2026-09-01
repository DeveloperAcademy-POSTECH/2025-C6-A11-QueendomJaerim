//
//  DenpencyContainer.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Foundation
import SwiftData

final class DependencyContainer {
  static let defaultContainer: DependencyContainer = .init()

  lazy var connectionManager: ConnectionManagerProtocol = ConnectionManager()
  lazy var networkManager: NetworkManagerProtocol = NetworkManager(connectionManager: connectionManager)
  lazy var pairedDeviceRegistry: WAPairedDeviceRegistryProtocol = WAPairedDeviceRegistry(
    repository: deviceRepository
  )
  lazy var networkService: NetworkServiceProtocol = NetworkService(
    networkManager: networkManager,
    connectionManager: connectionManager,
    pairedDeviceRegistry: pairedDeviceRegistry
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

  private lazy var deviceRepository: DeviceRepositoryProtocol = DeviceRepository(
    modelContainer: Self.makeDeviceModelContainer()
  )

  func bootstrap() {
    _ = analyticsService
    _ = globalDeviceEventObserver
  }

  private static func makeDeviceModelContainer() -> ModelContainer {
    let logger = QueenLogger(category: "DependencyContainer")
    do {
      return try ModelContainer(for: StoredDevice.self)
    } catch {
      logger.error("상대 기기 영속 저장소 생성 실패, 인메모리 저장소로 폴백합니다: \(error)")
      do {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: StoredDevice.self, configurations: configuration)
      } catch {
        fatalError("상대 기기 인메모리 저장소 생성에도 실패했습니다: \(error)")
      }
    }
  }
}
