import AVFoundation
import UIKit
import OSLog

final class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let completion: ((UIImage?) -> Void)
  private let logger = Logger(subsystem: "com.queendom.camera", category: "CameraManager")


  init(completion: @escaping (UIImage?) -> Void) {
    self.completion = completion
  }

  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
    guard error == nil else {
      logger.error("Error while capturing photo")
      completion(nil)
      return
    }

    guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
      logger.error("Image not fetched.")
      completion(nil)
      return
    }

    completion(image)
  }
}
