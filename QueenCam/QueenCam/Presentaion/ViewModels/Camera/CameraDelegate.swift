import AVFoundation
import OSLog
import Photos
import UIKit

final class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let completion: ((UIImage?) -> Void)
  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "CameraDelegate")

  private var stillImageData: Data?
  private var livePhotoMovieURL: URL?

  init(completion: @escaping (UIImage?) -> Void) {
    self.completion = completion
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: (any Error)?
  ) {
    guard error == nil else {
      logger.error("Error while capturing photo")
      completion(nil)
      return
    }

    guard
      let imageData = photo.fileDataRepresentation(),
      let image = UIImage(data: imageData)
    else {
      logger.error("Image not fetched.")
      completion(nil)
      return
    }

    stillImageData = imageData
    completion(image)

  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL,
    duration: CMTime,
    photoDisplayTime: CMTime,
    resolvedSettings: AVCaptureResolvedPhotoSettings,
    error: Error?
  ) {

    guard error == nil else {
      logger.error("Error capturing Live Photo movie: \(error)")
      return
    }

    guard let stillImageData = stillImageData else { return }

    saveLivePhotoToPhotosLibrary(
      stillImageData: stillImageData,
      livePhotoMovieURL: outputFileURL
    )
  }
}

extension CameraDelegate {
  private func saveLivePhotoToPhotosLibrary(stillImageData: Data, livePhotoMovieURL: URL) {
    PHPhotoLibrary.shared().performChanges({
      let creationRequest = PHAssetCreationRequest.forAsset()

      creationRequest.addResource(with: .photo, data: stillImageData, options: nil)

      let options = PHAssetResourceCreationOptions()
      options.shouldMoveFile = true
      creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoMovieURL, options: options)

    }) { success, error in
      if success {
        self.logger.info("Live Photo saved successfully.")
      } else if let error {
        self.logger.error("Failed to save Live Photo: \(error.localizedDescription)")
      }

    }
  }
}
