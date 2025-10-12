import AVFoundation
import Foundation
import Photos
import UIKit

@Observable
@MainActor
final class CameraViewModel {
  let manager = CameraManager()

  var isCameraPermissionGranted = false
  var isPhotosPermissionGranted = false
  var isMicPermissionGranted = false

  var isShowSettingAlert = false

  var lastImage: UIImage?

  var selectedZoom: CGFloat = 1.0

  var isLivePhotoOn = false

  var cameraPostion: AVCaptureDevice.Position?
  var currentFlashMode: AVCaptureDevice.FlashMode = .off

  init() {
    manager.onPhotoCapture = { [weak self] image in
      self?.lastImage = image
    }

    manager.onTapCamerSwitch = { [weak self] position in
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

  func zoom(factor: CGFloat) {
    selectedZoom = factor
    manager.setZoomScale(factor: factor)
  }

  func switchCamera() {
    manager.switchCamera()
  }

  func switchFlashMode() {
    switch currentFlashMode {
    case .off:
      currentFlashMode = .on
    case .on:
      currentFlashMode = .auto
    case .auto:
      currentFlashMode = .off

    @unknown default:
      currentFlashMode = .off
    }

    manager.flashMode = currentFlashMode
  }

  func switchLivePhoto() {
    isLivePhotoOn.toggle()
    manager.isLivePhotoOn = isLivePhotoOn
  }

}
