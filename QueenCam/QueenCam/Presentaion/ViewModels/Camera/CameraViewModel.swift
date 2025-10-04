import Foundation
import AVFoundation

@Observable
@MainActor
final class CameraViewModel {
  
  var isPermissionGranted = false
  var isShowSettingAlert = false
  
  func checkPermission() async {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    
    switch status {
    case .notDetermined:
      let granted = await AVCaptureDevice.requestAccess(for: .video)
      if granted {
        isPermissionGranted = true
      } else {
        isPermissionGranted = false
        isShowSettingAlert = true
      }
      
    case .restricted, .denied:
      isPermissionGranted = false
      isShowSettingAlert = true

    case .authorized:
      isPermissionGranted = true
      
    @unknown default:
      isPermissionGranted = false
    }
  }
}
