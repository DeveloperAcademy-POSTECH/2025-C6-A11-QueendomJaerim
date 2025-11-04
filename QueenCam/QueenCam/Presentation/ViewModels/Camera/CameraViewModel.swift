import AVFoundation
import Foundation
import Photos
import UIKit

@Observable
@MainActor
final class CameraViewModel {
  let cameraManager: CameraManager
  let networkService: NetworkServiceProtocol
  let cameraSettingsService: CameraSettingsServiceProtocol

  var isCameraPermissionGranted = false
  var isPhotosPermissionGranted = false
  var isMicPermissionGranted = false

  var isShowSettingAlert = false

  var lastImage: UIImage?

  var selectedZoom: CGFloat = 1.0

  var isLivePhotoOn: Bool
  var isShowGrid: Bool
  var isFlashMode: FlashMode

  var cameraPostion: AVCaptureDevice.Position?

  var errorMessage = ""

  // MARK: State Toast
  private let notificationService: NotificationServiceProtocol

  init(
    previewCaptureService: PreviewCaptureService,
    networkService: NetworkServiceProtocol,
    cameraSettingsService: CameraSettingsServiceProtocol,
    notificationService: NotificationServiceProtocol
  ) {
    self.networkService = networkService
    self.cameraSettingsService = cameraSettingsService
    self.cameraManager = CameraManager(
      previewCaptureService: previewCaptureService,
      networkService: networkService
    )

    self.isLivePhotoOn = cameraSettingsService.livePhotoOn
    self.isShowGrid = cameraSettingsService.gridOn
    self.isFlashMode = cameraSettingsService.flashMode

    self.notificationService = notificationService

    cameraManager.isLivePhotoOn = isLivePhotoOn
    cameraManager.flashMode = isFlashMode.convertAVCaptureDeviceFlashMode

    cameraManager.onPhotoCapture = { [weak self] image in
      self?.lastImage = image
    }

    cameraManager.onTapCameraSwitch = { [weak self] position in
      self?.cameraPostion = position
      if position == .back {
        self?.selectedZoom = 1.0
      }
    }
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
    } else {
      isShowSettingAlert = true
    }
  }

  func stopSession() {
    cameraManager.stopSession()
  }

  func capturePhoto() {
    cameraManager.capturePhoto()
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
