import AVFoundation
import OSLog
import Photos
import UIKit

final class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "CameraDelegate")
  private let isCameraPosition: AVCaptureDevice.Position

  private let completion: ((PhotoOuput?) -> Void)
  private var lastThumbnailImage: UIImage?
  private var lastStillImageData: Data?
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
      let image = UIImage(data: imageData)
    else {
      logger.error("Image not fetched.")
      completion(nil)
      return
    }

    lastThumbnailImage = image
    lastStillImageData = imageData

    let capturingLivePhoto =
      (photo.resolvedSettings.livePhotoMovieDimensions.width > 0 && photo.resolvedSettings.livePhotoMovieDimensions.height > 0)

    if !capturingLivePhoto {
      PhotoLibraryHelpers.saveToPhotoLibrary(image)
      completion(.basicPhoto(thumbnail: image, imageData: imageData))
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

    guard let lastStillImageData = lastStillImageData,
      let lastThumbnailImage = lastThumbnailImage,
      let movieData = try? Data(contentsOf: outputFileURL)
    else { return }

    PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(
      stillImageData: lastStillImageData,
      livePhotoMovieURL: outputFileURL
    )

    completion(.livePhoto(thumbnail: lastThumbnailImage, imageData: lastStillImageData, videoData: movieData))
  }
}
