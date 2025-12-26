import AVFoundation
import OSLog
import Photos
import UIKit

final class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let logger = QueenLogger(category: "CameraDelegate")
  private let isCameraPosition: AVCaptureDevice.Position

  private let completion: ((PhotoOuput?) -> Void)
  private var lastThumbnailImage: UIImage?
  private var lastStillImageData: Data?
  private var livePhotoMovieURL: URL?

  private var isLivePhoto: Bool = false
  private var willCaptureLivePhoto: (() -> Void)?

  init(
    isCameraPosition: AVCaptureDevice.Position,
    willCaptureLivePhoto: (() -> Void)? = nil,
    completion: @escaping (PhotoOuput?) -> Void
  ) {
    self.isCameraPosition = isCameraPosition
    self.willCaptureLivePhoto = willCaptureLivePhoto
    self.completion = completion
  }

  func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    isLivePhoto = (resolvedSettings.livePhotoMovieDimensions.width > 0 && resolvedSettings.livePhotoMovieDimensions.height > 0)

    if isLivePhoto {
      willCaptureLivePhoto?()
    }
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?,
    error: (any Error)?
  ) {
    guard error == nil else {
      logger.error("Deferred Photo Proxy Error: \(error)")
      completion(nil)
      return
    }

    guard let deferredPhotoProxy,
      let imageData = deferredPhotoProxy.fileDataRepresentation()

    else {
      logger.error("Deferred proxy is nil or no data")
      completion(nil)
      return
    }
    
    logger.info("Deferred processing started.")
    PhotoLibraryHelpers.saveProxyToPhotoLibrary(imageData)
    completion(.basicPhoto(thumbnail: UIImage(data: imageData) ?? .init(), imageData: imageData))

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

    if !isLivePhoto {
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
      completion(nil)
      return
    }

    guard let lastStillImageData = lastStillImageData,
      let lastThumbnailImage = lastThumbnailImage,
      let movieData = try? Data(contentsOf: outputFileURL)
    else {
      completion(nil)
      return
    }

    PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(
      stillImageData: lastStillImageData,
      livePhotoMovieURL: outputFileURL
    )

    completion(.livePhoto(thumbnail: lastThumbnailImage, imageData: lastStillImageData, videoData: movieData))
  }
}
