import AVFoundation
import Foundation
import Photos
import UIKit

@Observable
@MainActor
final class CameraViewModel {
  let manager = CameraManager(
    previewCaptureService: DependencyContainer.defaultContainer.previewCaptureService,
    networkService: DependencyContainer.defaultContainer.networkService
  )
  let networkService = DependencyContainer.defaultContainer.networkService

  let cameraSettings: CameraSettings

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

  init(cameraSettings: CameraSettings) {
    self.cameraSettings = cameraSettings
    self.isLivePhotoOn = cameraSettings.livePhotoOn
    self.isShowGrid = cameraSettings.gridOn
    self.isFlashMode = cameraSettings.flashMode

    manager.isLivePhotoOn = isLivePhotoOn
    manager.flashMode = isFlashMode.convertAVCaptureDeviceFlashMode

    manager.onPhotoCapture = { [weak self] image in
      self?.lastImage = image
    }

    manager.onTapCameraSwitch = { [weak self] position in
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
      try? await manager.configureSession()
    } else {
      isShowSettingAlert = true
    }
  }

  func stopSession() {
    manager.stopSession()
  }

  func capturePhoto() {
    manager.capturePhoto()
  }

  func setZoom(factor: CGFloat, ramp: Bool) {
    if ramp {
      selectedZoom = factor
    }

    manager.setZoomScale(factor: factor, ramp: ramp)
  }

  func switchCamera() async {
    do {
      try await manager.switchCamera()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func switchFlashMode() {
    switch isFlashMode {
    case .off: isFlashMode = .on
    case .on: isFlashMode = .auto
    case .auto: isFlashMode = .off
    }

    cameraSettings.flashMode = isFlashMode
    manager.flashMode = isFlashMode.convertAVCaptureDeviceFlashMode
  }

  func switchLivePhoto() {
    isLivePhotoOn.toggle()
    cameraSettings.livePhotoOn = isLivePhotoOn
    manager.isLivePhotoOn = isLivePhotoOn
  }

  func setFocus(point: CGPoint) {
    manager.focusAndExpose(at: point)
  }

  func switchGrid() {
    isShowGrid.toggle()
    cameraSettings.gridOn = isShowGrid
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
