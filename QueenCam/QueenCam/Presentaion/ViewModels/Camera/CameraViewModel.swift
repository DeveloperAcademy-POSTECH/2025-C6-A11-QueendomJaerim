import AVFoundation
import Foundation
import UIKit

@Observable
@MainActor
final class CameraViewModel {
  let manager = CameraManager()

  var isPermissionGranted = false
  var isShowSettingAlert = false

  var lastImage: UIImage?

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

    @unknown default:
      isPermissionGranted = false
    }
  }

  func stopSession() {
    manager.stopSession()
  }

  func capturePhoto() {
    manager.capturePhoto()
  }
}
