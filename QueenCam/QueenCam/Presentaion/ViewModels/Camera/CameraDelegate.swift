import AVFoundation
import UIKit

final class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let completion: ((UIImage?) -> Void)
  
  init(completion: @escaping (UIImage?) -> Void) {
    self.completion = completion
  }
  
   func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
    guard error == nil else {
      print("CameraManager: Error while capturing photo: \(error?.localizedDescription)")
      completion(nil)
      return
    }
    
    guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
      print("CameraManager: Image not fetched.")
      completion(nil)
      return
    }
    
    completion(image)
  }
}
