import AVFoundation
import Foundation
import Photos
import UIKit

@Observable
@MainActor
final class CameraViewModel {
  let manager = CameraManager()

  var isPermissionGranted = false
  var isShowSettingAlert = false
  var isPhotosPermissionGranted = false

  var lastImage: UIImage?

  var selectedZoom: CGFloat = 1.0

  init() {
    manager.onPhotoCapture = { [weak self] image in
      self?.lastImage = image
    }
  }

  func checkPermission() async {
    let status = AVCaptureDevice.authorizationStatus(for: .video)

    switch status {
    case .notDetermined:
      let granted = await AVCaptureDevice.requestAccess(for: .video)
      if granted {
        isPermissionGranted = true
        try? await manager.configureSession()
        zoom(factor: 1.0)
      } else {
        isPermissionGranted = false
        isShowSettingAlert = true
      }

    case .restricted, .denied:
      isPermissionGranted = false
      isShowSettingAlert = true

    case .authorized:
      isPermissionGranted = true
      try? await manager.configureSession()
      zoom(factor: 1.0)

    @unknown default:
      isPermissionGranted = false
    }
  }

  func checkPhotosPermission() async {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    switch status {
    case .authorized, .limited:
      isPhotosPermissionGranted = true
    case .notDetermined:
      let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
      if newStatus == .authorized || newStatus == .limited {
        isPhotosPermissionGranted = true
      } else {
        isPhotosPermissionGranted = false
      }
    case .denied, .restricted:
      isPhotosPermissionGranted = false

    @unknown default:
      isPhotosPermissionGranted = false
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
}
