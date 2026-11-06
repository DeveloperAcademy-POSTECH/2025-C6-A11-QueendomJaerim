//
//  CameraViewModelAspectRatioSyncTests.swift
//  QueenCamTests
//
//  Created by seungchan on 11/5/26.
//

import Combine
import Foundation
import Testing
import WiFiAware

@testable import QueenCam

@Suite("CameraViewModel 비율 동기화 Tests")
@MainActor
struct CameraViewModelAspectRatioSyncTests {
  @Test("버전 확인을 통과하기 전에는 비율을 바꿔도 보내지 않고 내 기기에만 저장한다")
  func doesNotSendBeforeVersionVerified() async throws {
    let (viewModel, network, settings) = makeViewModel(role: .photographer, isVersionVerified: false)

    viewModel.switchPhotoAspectRatio()
    try await Task.sleep(for: .milliseconds(50))

    #expect(viewModel.photoAspectRatio == .ratio16x9)
    #expect(settings.photoAspectRatio == .ratio16x9)
    #expect(network.sentAspectRatios.isEmpty)
  }

  @Test("버전 확인을 통과한 작가가 비율을 바꾸면 모델에게 보낸다")
  func photographerSendsAfterVersionVerified() async {
    let (viewModel, network, _) = makeViewModel(role: .photographer, isVersionVerified: true)

    viewModel.switchPhotoAspectRatio()

    #expect(await waitUntil { network.sentAspectRatios == [.ratio16x9] })
  }

  @Test("모델은 비율을 바꿔도 보내지 않는다")
  func modelDoesNotSend() async throws {
    let (viewModel, network, _) = makeViewModel(role: .model, isVersionVerified: true)

    viewModel.switchPhotoAspectRatio()
    try await Task.sleep(for: .milliseconds(50))

    #expect(network.sentAspectRatios.isEmpty)
  }

  @Test("모델이 비율을 받으면 현재 비율과 저장값을 바꾼다")
  func modelAppliesReceivedRatio() async {
    let (viewModel, network, settings) = makeViewModel(role: .model, isVersionVerified: true)

    network.emit(.photoAspectRatio(.ratio1x1))

    #expect(await waitUntil { viewModel.photoAspectRatio == .ratio1x1 })
    #expect(settings.photoAspectRatio == .ratio1x1)
  }

  @Test("작가는 비율을 받아도 무시한다")
  func photographerIgnoresReceivedRatio() async throws {
    let (viewModel, network, settings) = makeViewModel(role: .photographer, isVersionVerified: true)

    network.emit(.photoAspectRatio(.ratio1x1))
    try await Task.sleep(for: .milliseconds(50))

    #expect(viewModel.photoAspectRatio == .ratio4x3)
    #expect(settings.photoAspectRatio == .ratio4x3)
  }

  @Test("작가는 상대 버전 확인을 통과하면 지금 비율을 한 번 보낸다")
  func photographerSendsCurrentRatioWhenVersionVerified() async throws {
    let (viewModel, network, _) = makeViewModel(role: .photographer, isVersionVerified: true)

    network.emit(.myVersion(compatibleVersion))

    #expect(await waitUntil { network.sentAspectRatios == [.ratio4x3] })
    try await Task.sleep(for: .milliseconds(50))
    #expect(network.sentAspectRatios == [.ratio4x3])
    withExtendedLifetime(viewModel) {}
  }

  @Test("모델은 상대 버전 확인을 통과해도 비율을 보내지 않는다")
  func modelDoesNotSendWhenVersionVerified() async throws {
    let (viewModel, network, _) = makeViewModel(role: .model, isVersionVerified: true)

    network.emit(.myVersion(compatibleVersion))
    try await Task.sleep(for: .milliseconds(50))

    #expect(network.sentAspectRatios.isEmpty)
    withExtendedLifetime(viewModel) {}
  }

  @Test("상대 버전 확인에 실패하면 작가도 비율을 보내지 않는다")
  func photographerDoesNotSendWhenVersionRejected() async throws {
    let (viewModel, network, _) = makeViewModel(role: .photographer, isVersionVerified: false)

    network.emit(.myVersion(compatibleVersion))
    try await Task.sleep(for: .milliseconds(50))

    #expect(network.sentAspectRatios.isEmpty)
    withExtendedLifetime(viewModel) {}
  }
}

private let compatibleVersion = VersionExchangePayload(version: VersionUtils.currentVersion, requiredMinimumVersion: 0)

// MARK: - Helpers

@MainActor
private func makeViewModel(
  role: Role?,
  isVersionVerified: Bool
) -> (CameraViewModel, FakeNetworkService, FakeCameraSettingsService) {
  let network = FakeNetworkService()
  network.isCounterpartVersionVerified = isVersionVerified
  let settings = FakeCameraSettingsService()

  let viewModel = CameraViewModel(
    previewCaptureService: PreviewCaptureService(),
    networkService: network,
    cameraSettingsService: settings,
    notificationService: FakeNotificationService(),
    guidingStrokeRepository: GuidingStrokeRepository(networkService: network)
  )
  viewModel.currentRole = role

  return (viewModel, network, settings)
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async -> Bool {
  for _ in 0..<200 {
    if condition() { return true }
    try? await Task.sleep(for: .milliseconds(10))
  }
  return false
}

private final class FakeNetworkService: NetworkServiceProtocol {
  var mode: NetworkType?
  var networkState: NetworkState?
  var lastStopReason: String?
  var isCounterpartVersionVerified = false

  private let networkEventSubject = PassthroughSubject<NetworkEvent?, Never>()
  private(set) var sentAspectRatios: [PhotoAspectRatio] = []

  var deviceConnectionsPublisher: AnyPublisher<[WAPairedDevice: ConnectionDetail], Never> {
    Empty().eraseToAnyPublisher()
  }

  var lastErrorPublisher: AnyPublisher<Error?, Never> {
    Empty().eraseToAnyPublisher()
  }

  var networkStatePublisher: AnyPublisher<NetworkState?, Never> {
    Empty().eraseToAnyPublisher()
  }

  var networkEventPublisher: AnyPublisher<NetworkEvent?, Never> {
    networkEventSubject.eraseToAnyPublisher()
  }

  var deviceReportsPublisher: AnyPublisher<[WAPairedDevice: WAPerformanceReport], Never> {
    Empty().eraseToAnyPublisher()
  }

  func run(for device: WAPairedDevice) {}
  func reconnect(for device: WAPairedDevice) {}
  func stop(byUser: Bool, userReason: String?) {}
  func disconnect() {}

  func send(for event: NetworkEvent) async {
    if case .photoAspectRatio(let ratio) = event {
      sentAspectRatios.append(ratio)
    }
  }

  func emit(_ event: NetworkEvent) {
    networkEventSubject.send(event)
  }
}

private final class FakeCameraSettingsService: CameraSettingsServiceProtocol {
  var livePhotoOn = false
  var gridOn = false
  var flashMode: FlashMode = .off
  var saveGuidingOverlayImageOn = false
  var photoAspectRatio: PhotoAspectRatio = .ratio4x3
}

private final class FakeNotificationService: NotificationServiceProtocol {
  var currentNotification: DomainNotification?

  var lastNotificationPublisher: AnyPublisher<DomainNotification?, Never> {
    Empty().eraseToAnyPublisher()
  }

  func registerNotification(_ notification: DomainNotification) {
    currentNotification = notification
  }

  func reset() {
    currentNotification = nil
  }

  func registerBaseNotification(_ notification: DomainNotification) {
    currentNotification = notification
  }

  func resetBaseNotification() {
    currentNotification = nil
  }
}
