import AVFoundation
import Combine
import Foundation
import Photos
import SwiftUI
import UIKit

@Observable
@MainActor
final class CameraViewModel {
  let cameraManager: CameraManager
  let cameraSettingsService: CameraSettingsServiceProtocol

  var isCameraPermissionGranted = false
  var isPhotosPermissionGranted = false
  var isMicPermissionGranted = false

  var selectedZoom: CGFloat = 1.0

  var isLivePhotoOn: Bool
  var isShowGrid: Bool
  var isFlashMode: FlashMode

  var cameraPostion: AVCaptureDevice.Position?
  var selectedCameraDeviceType: AVCaptureDevice.DeviceType?

  var selectedPhotoAspectRatio: PhotoAspectRatio = .ratio4x3
  /// 현재 사진 비율 상태를 마지막으로 확정한 LWW 기록
  var lastPhotoAspectRatioLWWRegister: LWWRegister?

  var errorMessage = ""

  var isCaptureButtonEnabled: Bool = true

  var isCapturingLivePhoto: Bool = false

  // MARK: Thumbnail
  var thumbnailImage: UIImage?
  private let photosLibraryObserver = PhotosLibraryObserver()
  private var displayScale: CGFloat = 1.0
  /// 사진 비율 동기화 이벤트를 구분하기 위한 현재 디바이스 식별자
  private let photoAspectRatioActorId = UUID().uuidString
  /// 현재 세션에서 사진 비율 초기화를 완료했는지 나타내는 플래그
  private var isAspectRatioSessionInitialized: Bool = false

  private var cancellables: Set<AnyCancellable> = []

  private let logger = QueenLogger(category: "CameraViewModel")

  // MARK: State Toast
  private let notificationService: NotificationServiceProtocol

  init(
    cameraManager: CameraManager,
    cameraSettingsService: CameraSettingsServiceProtocol,
    notificationService: NotificationServiceProtocol
  ) {
    self.cameraSettingsService = cameraSettingsService
    self.cameraManager = cameraManager
    self.notificationService = notificationService

    self.isLivePhotoOn = cameraSettingsService.livePhotoOn
    self.isShowGrid = cameraSettingsService.gridOn
    self.isFlashMode = cameraSettingsService.flashMode

    cameraManager.isLivePhotoOn = isLivePhotoOn
    cameraManager.flashMode = isFlashMode.convertAVCaptureDeviceFlashMode

    cameraManager.onWillCaptureLivePhoto = { [weak self] in
      self?.isCapturingLivePhoto = true
    }

    cameraManager.onDidFinishCapture = { [weak self] in
      self?.isCapturingLivePhoto = false
    }

    cameraManager.onPhotoCapture = { [weak self] image in
      self?.thumbnailImage = image
    }

    cameraManager.onTapCameraSwitch = { [weak self] position in
      self?.cameraPostion = position
      if position == .back {
        self?.selectedZoom = 1.0
      }
    }

    cameraManager.onSelectedCameraDeviceType = { [weak self] deviceType in
      self?.selectedCameraDeviceType = deviceType
    }

    cameraManager.onReadinessState = { [weak self] readiness in
      self?.handleReadiness(readiness: readiness)
    }

    photosLibraryObserver.onUpdate = { [weak self] image in
      self?.thumbnailImage = image
    }

    photosLibraryObserver.getCurrentScale = { [weak self] in
      self?.displayScale ?? 1.0
    }

    bind()

    // 역할 변경을 세션 시작 이벤트로 보고 비율을 4:3으로 초기화하기 위해 구독
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRoleChangedNotification(notification:)),
      name: .QueenCamRoleChangedNotification,
      object: nil
    )
  }

  deinit {
    // NotificationCenter observer 정리
    NotificationCenter.default.removeObserver(self)
  }

  func checkPermissions() async {
    let cameraGranted: Bool
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined:
      cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
    case .authorized:
      cameraGranted = true
    default:
      cameraGranted = false
    }

    let audioGranted: Bool
    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .notDetermined:
      audioGranted = await AVCaptureDevice.requestAccess(for: .audio)
    case .authorized:
      audioGranted = true
    default:
      audioGranted = false
    }

    let photoGranted: Bool
    switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
    case .notDetermined:
      let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
      photoGranted = (newStatus == .authorized || newStatus == .limited)
    case .authorized, .limited:
      photoGranted = true
    default:
      photoGranted = false
    }

    if cameraGranted && audioGranted {
      isCameraPermissionGranted = true
      isMicPermissionGranted = true
      isPhotosPermissionGranted = photoGranted
      try? await cameraManager.configureSession()
    }
  }

  func stopSession() {
    cameraManager.stopSession()
  }

  func capturePhoto() {
    traceShutterPressedEvent()
    cameraManager.capturePhoto(selectedPhotoAspectRatio: selectedPhotoAspectRatio)
  }

  func setPhotoAspectRatio(ratio: PhotoAspectRatio) {
    let lwwRegister = LWWRegister(actorId: photoAspectRatioActorId, timestamp: .init())
    updatePhotoAspectRatio(ratio: ratio, lwwRegister: lwwRegister)

    let isConnected =
      cameraManager.networkService.networkState == .host(.publishing)
      || cameraManager.networkService.networkState == .viewer(.connected)

    guard isConnected else { return }

    Task {
      await cameraManager.networkService.send(for: .photoAspectRatio(.init(ratio: ratio, lwwRegister: lwwRegister)))
    }
  }

  func setZoom(factor: CGFloat, ramp: Bool) {
    if ramp {
      selectedZoom = factor
    }

    cameraManager.setZoomScale(factor: factor, ramp: ramp)
  }

  func switchCamera() async {
    do {
      try await cameraManager.switchCamera()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func showLivePhotoToast() {
    notificationService.registerNotification(DomainNotification.make(type: .captureLivePhoto))
  }

  func switchFlashMode() {
    switch isFlashMode {
    case .off:
      isFlashMode = .on
      notificationService.registerNotification(DomainNotification.make(type: .flashOn))
    case .on:
      isFlashMode = .auto
      notificationService.registerNotification(DomainNotification.make(type: .flashAuto))
    case .auto:
      isFlashMode = .off
      notificationService.registerNotification(DomainNotification.make(type: .flashOff))
    }

    cameraSettingsService.flashMode = isFlashMode
    cameraManager.flashMode = isFlashMode.convertAVCaptureDeviceFlashMode
  }

  func switchLivePhoto() {
    switch isLivePhotoOn {
    case true:
      isLivePhotoOn = false
      notificationService.registerNotification(DomainNotification.make(type: .liveOff))
    case false:
      isLivePhotoOn = true
      notificationService.registerNotification(DomainNotification.make(type: .liveOn))
    }

    cameraSettingsService.livePhotoOn = isLivePhotoOn
    cameraManager.isLivePhotoOn = isLivePhotoOn
  }

  func setFocus(point: CGPoint) {
    cameraManager.focusAndExpose(at: point)
  }

  func switchGrid() {
    isShowGrid.toggle()
    cameraSettingsService.gridOn = isShowGrid
  }

  func loadThumbnail(scale: CGFloat) async {
    await photosLibraryObserver.loadThumbnail(scale: scale)
  }

  func managePhotosPickerToast(isShowPhotosPicker: Bool) {
    if isShowPhotosPicker {
      notificationService.registerNotification(.make(type: .photosPickerShowing))
    } else {
      if let currentNotification = notificationService.currentNotification,
        currentNotification.isType(of: .photosPickerShowing)
      {
        notificationService.reset()
      }
    }
  }
}

// MARK: - Readiness
extension CameraViewModel {
  /// 카메라 촬영 가능 상태를 반영해 촬영 버튼 활성 여부를 갱신한다.
  private func handleReadiness(readiness: AVCapturePhotoOutput.CaptureReadiness) {
    switch readiness {
    case .sessionNotRunning:
      isCaptureButtonEnabled = false
    case .ready:
      isCaptureButtonEnabled = true
    case .notReadyMomentarily:
      isCaptureButtonEnabled = false
    case .notReadyWaitingForCapture:
      isCaptureButtonEnabled = false
    case .notReadyWaitingForProcessing:
      isCaptureButtonEnabled = false
    @unknown default:
      isCaptureButtonEnabled = false
    }
  }
}

// MARK: - Photo Aspect Ratio Sync
extension CameraViewModel {
  /// 사진 비율 변경이 현재 상태보다 최신일 때만 선택 비율과 LWW 기록을 갱신한다.
  private func updatePhotoAspectRatio(ratio: PhotoAspectRatio, lwwRegister: LWWRegister) {
    if let lastPhotoAspectRatioLWWRegister {
      if lwwRegister.timestamp > lastPhotoAspectRatioLWWRegister.timestamp {
        selectedPhotoAspectRatio = ratio
        self.lastPhotoAspectRatioLWWRegister = lwwRegister
      } else if lwwRegister.timestamp == lastPhotoAspectRatioLWWRegister.timestamp,
        lwwRegister.actorId > lastPhotoAspectRatioLWWRegister.actorId
      {
        selectedPhotoAspectRatio = ratio
        self.lastPhotoAspectRatioLWWRegister = lwwRegister
      }
    } else {
      selectedPhotoAspectRatio = ratio
      self.lastPhotoAspectRatioLWWRegister = lwwRegister
    }
  }

  /// 상대 기기에서 수신한 사진 비율 변경 이벤트를 동일한 LWW 경로로 반영한다.
  private func handleReceivedPhotoAspectRatio(payload: PhotoAspectRatioPayload) {
    updatePhotoAspectRatio(
      ratio: payload.ratio,
      lwwRegister: payload.lwwRegister
    )
  }
}

// MARK: - Binding
extension CameraViewModel {
  /// 네트워크 이벤트와 연결 상태 변화를 구독해 사진 비율 동기화 로직에 연결한다.
  private func bind() {
    cameraManager.networkService.networkEventPublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] event in
        switch event {
        case .photoAspectRatio(let payload):
          self?.handleReceivedPhotoAspectRatio(payload: payload)
        default:
          break
        }
      }
      .store(in: &cancellables)

    cameraManager.networkService.networkStatePublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] state in
        self?.handleNetworkStateChanged(state)
      }
      .store(in: &cancellables)
  }
}

// MARK: - Session Reset
extension CameraViewModel {
  /// 역할 변경 알림을 수신하면 새 세션 시작 정책에 따라 사진 비율을 기본값으로 초기화한다.
  @objc private func handleRoleChangedNotification(notification: Notification) {
    guard notification.userInfo?["newRole"] as? Role != nil else { return }
    resetPhotoAspectRatioForSessionStart()
  }

  /// 세션 시작 상태에서는 공통 시작 비율인 `4:3`을 로컬과 상대 기기에 함께 반영한다.
  private func resetPhotoAspectRatioForSessionStart() {
    let lwwRegister = LWWRegister(actorId: photoAspectRatioActorId, timestamp: .init())

    updatePhotoAspectRatio(ratio: .ratio4x3, lwwRegister: lwwRegister)

    let isConnected =
      cameraManager.networkService.networkState == .host(.publishing)
      || cameraManager.networkService.networkState == .viewer(.connected)

    guard isConnected else { return }

    Task {
      await cameraManager.networkService.send(for: .photoAspectRatio(.init(ratio: .ratio4x3, lwwRegister: lwwRegister)))
    }
  }

  /// 연결 상태 변화에 따라 세션 시작/종료 시점의 사진 비율 초기화 정책을 수행한다.
  private func handleNetworkStateChanged(_ state: NetworkState) {
    if isAspectRatioSessionStartState(state) {
      if !isAspectRatioSessionInitialized {
        isAspectRatioSessionInitialized = true
        resetPhotoAspectRatioForSessionStart()
      }
    } else if isAspectRatioSessionEndState(state) {
      resetPhotoAspectRatioForSessionEnd()
    }
  }

  /// 세션 종료 상태에서는 로컬 사진 비율을 기본값 `4:3`으로 되돌리고 초기화 플래그를 해제한다.
  private func resetPhotoAspectRatioForSessionEnd() {
    let lwwRegister = LWWRegister(
      actorId: photoAspectRatioActorId,
      timestamp: Date()
    )

    updatePhotoAspectRatio(ratio: .ratio4x3, lwwRegister: lwwRegister)
    isAspectRatioSessionInitialized = false
  }

  /// 연결 성립 또는 재연결처럼 세션 시작으로 간주할 상태인지 판단한다.
  private func isAspectRatioSessionStartState(_ state: NetworkState) -> Bool {
    state == .host(.publishing) || state == .viewer(.connected)
  }

  /// 연결 종료, 유실, 취소처럼 세션 종료로 간주할 상태인지 판단한다.
  private func isAspectRatioSessionEndState(_ state: NetworkState) -> Bool {
    state == .host(.stopped)
      || state == .viewer(.stopped)
      || state == .host(.cancelled)
      || state == .viewer(.cancelled)
      || state == .host(.lost)
      || state == .viewer(.lost)
  }
}

extension FlashMode {
  var convertAVCaptureDeviceFlashMode: AVCaptureDevice.FlashMode {
    switch self {
    case .off:
      return .off
    case .on:
      return .on
    case .auto:
      return .auto
    }
  }
}
