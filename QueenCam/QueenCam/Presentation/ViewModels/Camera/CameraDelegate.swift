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
  private var deferredPhotoProxyData: Data?
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

    if isLivePhoto {
      self.deferredPhotoProxyData = imageData
      if let livePhotoMovieURL = self.livePhotoMovieURL,
        let movieData = try? Data(contentsOf: livePhotoMovieURL),
        let thumbnail = UIImage(data: imageData)
      {
        logger.info("Live Photo: Saving deferred live photo (Proxy delegate).")
        completion(.livePhoto(thumbnail: thumbnail, imageData: imageData, videoData: movieData, isDeferred: true))
      }
    } else {
      completion(.basicPhoto(thumbnail: UIImage(data: imageData) ?? .init(), imageData: imageData, isProxy: true))
    }
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
      completion(.basicPhoto(thumbnail: image, imageData: imageData, isProxy: false))
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

    self.livePhotoMovieURL = outputFileURL

    // 지연 처리된 라이브 포토
    if let deferredPhotoProxyData = self.deferredPhotoProxyData,
      let movieData = try? Data(contentsOf: outputFileURL),
      let thumbnail = UIImage(data: deferredPhotoProxyData)
    {
      logger.info("Live Photo: Saving deferred live photo (Movie delegate).")
      completion(.livePhoto(
        thumbnail: thumbnail,
        imageData: deferredPhotoProxyData,
        videoData: movieData,
        isDeferred: true
      ))
      return
    }

    // 일반 라이브 포토
    if let lastStillImageData = self.lastStillImageData,
      let lastThumbnailImage = self.lastThumbnailImage,
      let movieData = try? Data(contentsOf: outputFileURL)
    {
      logger.info("Live Photo: Saving standard live photo (Movie delegate).")
      completion(.livePhoto(
        thumbnail: lastThumbnailImage,
        imageData: lastStillImageData,
        videoData: movieData,
        isDeferred: false
      ))
      return
    }
  }
}
