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

  @Test("역할 교환으로 모델이 작가가 되면 지금 비율을 보낸다")
  func newPhotographerSendsCurrentRatio() async {
    let (viewModel, network, _) = makeViewModel(role: .model, isVersionVerified: true)

    viewModel.currentRole = .photographer

    #expect(await waitUntil { network.sentAspectRatios == [.ratio4x3] })
  }

  @Test("버전 확인을 통과하기 전에는 작가가 되어도 보내지 않는다")
  func newPhotographerDoesNotSendBeforeVersionVerified() async throws {
    let (viewModel, network, _) = makeViewModel(role: .model, isVersionVerified: false)

    viewModel.currentRole = .photographer
    try await Task.sleep(for: .milliseconds(50))

    #expect(network.sentAspectRatios.isEmpty)
  }

  @Test("처음 역할을 고르는 것은 역할 교환이 아니라서 보내지 않는다")
  func firstRoleSelectionDoesNotSend() async throws {
    let (viewModel, network, _) = makeViewModel(role: nil, isVersionVerified: true)

    viewModel.currentRole = .photographer
    try await Task.sleep(for: .milliseconds(50))

    #expect(network.sentAspectRatios.isEmpty)
  }

  @Test("모델이 되면 보내지 않고, 작가였다가 모델이 되어도 받은 늦은 값은 적용한다")
  func becomingModelDoesNotSendAndAppliesReceivedRatio() async throws {
    let (viewModel, network, _) = makeViewModel(role: .photographer, isVersionVerified: true)

    viewModel.currentRole = .model
    network.emit(.photoAspectRatio(.ratio1x1))

    #expect(await waitUntil { viewModel.photoAspectRatio == .ratio1x1 })
    #expect(network.sentAspectRatios.isEmpty)
  }

  @Test("새 작가가 된 뒤 도착한 이전 작가의 늦은 값은 버린다")
  func newPhotographerIgnoresLateRatioFromPreviousPhotographer() async throws {
    let (viewModel, network, _) = makeViewModel(role: .model, isVersionVerified: true)

    viewModel.currentRole = .photographer
    network.emit(.photoAspectRatio(.ratio16x9))
    try await Task.sleep(for: .milliseconds(50))

    #expect(viewModel.photoAspectRatio == .ratio4x3)
  }

  @Test("작가가 모델이 되면 작가에게 비율을 요청한다")
  func newModelRequestsRatio() async {
    let (viewModel, network, _) = makeViewModel(role: .photographer, isVersionVerified: true)

    viewModel.currentRole = .model

    #expect(await waitUntil { network.requestCount == 1 })
    #expect(network.sentAspectRatios.isEmpty)
  }

  @Test("버전 확인을 통과하기 전에는 모델이 되어도 요청하지 않는다")
  func newModelDoesNotRequestBeforeVersionVerified() async throws {
    let (viewModel, network, _) = makeViewModel(role: .photographer, isVersionVerified: false)

    viewModel.currentRole = .model
    try await Task.sleep(for: .milliseconds(50))

    #expect(network.requestCount == 0)
  }

  @Test("처음 모델 역할을 고를 때는 요청하지 않는다")
  func firstModelSelectionDoesNotRequest() async throws {
    let (viewModel, network, _) = makeViewModel(role: nil, isVersionVerified: true)

    viewModel.currentRole = .model
    try await Task.sleep(for: .milliseconds(50))

    #expect(network.requestCount == 0)
  }

  @Test("작가는 요청을 받으면 지금 비율로 답한다")
  func photographerRepliesToRequest() async {
    let (viewModel, network, _) = makeViewModel(role: .photographer, isVersionVerified: true)

    network.emit(.requestPhotoAspectRatio)

    #expect(await waitUntil { network.sentAspectRatios == [.ratio4x3] })
    withExtendedLifetime(viewModel) {}
  }

  @Test("모델은 요청을 받아도 답하지 않는다")
  func modelIgnoresRequest() async throws {
    let (viewModel, network, _) = makeViewModel(role: .model, isVersionVerified: true)

    network.emit(.requestPhotoAspectRatio)
    try await Task.sleep(for: .milliseconds(50))

    #expect(network.sentAspectRatios.isEmpty)
    withExtendedLifetime(viewModel) {}
  }

  @Test("작가의 비율 변경과 상대의 역할 교환이 겹쳐 메시지가 엇갈려도 두 기기는 새 작가의 값으로 끝난다")
  func overlappingRatioChangeAndRoleSwapConvergesToNewPhotographerRatio() async throws {
    // A: 작가, B: 모델. 둘 다 4:3. 메시지는 테스트가 정한 순서로 전달한다.
    let (deviceA, networkA, _) = makeViewModel(role: .photographer, isVersionVerified: true)
    let (deviceB, networkB, _) = makeViewModel(role: .model, isVersionVerified: true)

    // A가 비율 버튼을 누르고(16:9), 거의 동시에 B가 역할 교환으로 작가가 된다(4:3을 보냄)
    deviceA.switchPhotoAspectRatio()
    deviceB.currentRole = .photographer
    #expect(await waitUntil { networkA.sentAspectRatios == [.ratio16x9] && networkB.sentAspectRatios == [.ratio4x3] })

    // A의 16:9가 B에 도착: B는 이미 작가라서 버린다
    networkB.emit(.photoAspectRatio(.ratio16x9))
    try await Task.sleep(for: .milliseconds(50))
    #expect(deviceB.photoAspectRatio == .ratio4x3)

    // B의 4:3이 A의 역할이 바뀌기 전에 도착: A는 아직 작가라서 버린다
    networkA.emit(.photoAspectRatio(.ratio4x3))
    try await Task.sleep(for: .milliseconds(50))
    #expect(deviceA.photoAspectRatio == .ratio16x9)

    // 그 뒤에 A가 모델이 되어 요청을 보낸다
    deviceA.currentRole = .model
    #expect(await waitUntil { networkA.requestCount == 1 })

    // 요청이 B에 도착하면 B가 지금 비율로 답하고, 그 답이 A에 도착한다
    networkB.emit(.requestPhotoAspectRatio)
    #expect(await waitUntil { networkB.sentAspectRatios == [.ratio4x3, .ratio4x3] })
    networkA.emit(.photoAspectRatio(.ratio4x3))

    #expect(await waitUntil { deviceA.photoAspectRatio == .ratio4x3 })
    #expect(deviceB.photoAspectRatio == .ratio4x3)
    #expect(networkA.requestCount == 1)
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
  private(set) var requestCount = 0

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
    switch event {
    case .photoAspectRatio(let ratio):
      sentAspectRatios.append(ratio)
    case .requestPhotoAspectRatio:
      requestCount += 1
    default:
      break
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
