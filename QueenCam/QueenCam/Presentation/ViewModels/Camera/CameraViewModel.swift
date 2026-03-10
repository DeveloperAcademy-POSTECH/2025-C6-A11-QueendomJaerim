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
  var lastPhotoAspectRatioLWWRegister: LWWRegister?

  var errorMessage = ""

  var isCaptureButtonEnabled: Bool = true

  var isCapturingLivePhoto: Bool = false

  // MARK: Thumbnail
  var thumbnailImage: UIImage?
  private let photosLibraryObserver = PhotosLibraryObserver()
  private var displayScale: CGFloat = 1.0
  private let photoAspectRatioActorId = UUID().uuidString

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
    let lwwRegister = LWWRegister(
      actorId: photoAspectRatioActorId,
      timestamp: Date()
    )

    updatePhotoAspectRatio(ratio: ratio, lwwRegister: lwwRegister)
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

extension CameraViewModel {
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

extension CameraViewModel {
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
}

extension CameraViewModel {
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
  }

  private func handleReceivedPhotoAspectRatio(payload: PhotoAspectRatioPayload) {
    updatePhotoAspectRatio(
      ratio: payload.ratio,
      lwwRegister: payload.lwwRegister
    )
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
