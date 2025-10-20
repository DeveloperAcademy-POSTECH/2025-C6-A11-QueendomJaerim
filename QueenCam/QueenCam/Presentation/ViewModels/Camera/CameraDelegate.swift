import AVFoundation
import OSLog
import Photos
import UIKit

final class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "CameraDelegate")
  private let isCameraPosition: AVCaptureDevice.Position

  private let completion: ((PhotoOuput?) -> Void)
  private var stillImageData: Data?
  private var livePhotoMovieURL: URL?

  init(isCameraPosition: AVCaptureDevice.Position, completion: @escaping (PhotoOuput?) -> Void) {
    self.isCameraPosition = isCameraPosition
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
      var image = UIImage(data: imageData)
    else {
      logger.error("Image not fetched.")
      completion(nil)
      return
    }

    if isCameraPosition == .front {
      if let cgImage = image.cgImage {
        image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
      }
    }

    stillImageData = imageData
    completion(.init(uiImage: image, data: stillImageData))

    let capturingLivePhoto =
      (photo.resolvedSettings.livePhotoMovieDimensions.width > 0 && photo.resolvedSettings.livePhotoMovieDimensions.height > 0)

    if !capturingLivePhoto {
      saveToPhotoLibrary(image)
    }

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
  private func saveToPhotoLibrary(_ image: UIImage) {
    PHPhotoLibrary.shared().performChanges {
      PHAssetChangeRequest.creationRequestForAsset(from: image)
    } completionHandler: { success, error in
      if success {
        self.logger.info("Image saved to gallery.")
      } else if error != nil {
        self.logger.error("Error saving image to gallery")
      }
    }
  }

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
