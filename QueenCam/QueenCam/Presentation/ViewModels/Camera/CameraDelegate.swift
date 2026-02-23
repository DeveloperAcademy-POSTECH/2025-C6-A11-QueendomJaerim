import AVFoundation
import OSLog
import Photos
import UIKit

final class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let logger = QueenLogger(category: "CameraDelegate")
  private let isCameraPosition: AVCaptureDevice.Position
  private let selectedPhotoAspectRatio: PhotoAspectRatio

  private let completion: ((PhotoOuput?) -> Void)
  private var lastThumbnailImage: UIImage?
  private var lastStillImageData: Data?
  private var deferredPhotoProxyData: Data?
  private var livePhotoMovieURL: URL?

  private var isLivePhoto: Bool = false
  private var willCaptureLivePhoto: (() -> Void)?

  init(
    isCameraPosition: AVCaptureDevice.Position,
    selectedPhotoAspectRatio: PhotoAspectRatio,
    willCaptureLivePhoto: (() -> Void)? = nil,
    completion: @escaping (PhotoOuput?) -> Void
  ) {
    self.isCameraPosition = isCameraPosition
    self.selectedPhotoAspectRatio = selectedPhotoAspectRatio
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
        PhotoLibraryHelpers.saveDeferredLivePhotoToPhotosLibrary(
          proxyData: imageData,
          livePhotoMovieURL: livePhotoMovieURL
        )

        completion(.livePhoto(thumbnail: thumbnail, imageData: imageData, videoData: movieData))
      }
    } else {
      PhotoLibraryHelpers.saveProxyToPhotoLibrary(imageData)
      completion(.basicPhoto(thumbnail: UIImage(data: imageData) ?? .init(), imageData: imageData))
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
      if selectedPhotoAspectRatio == .ratio4x3 {
        PhotoLibraryHelpers.saveToPhotoLibrary(imageData)
        completion(.basicPhoto(thumbnail: image, imageData: imageData))
        return
      }

      guard
        let cropped = croppedImageData(
          from: imageData,
          targetRatio: selectedPhotoAspectRatio.value
        )
      else {
        logger.error("Failed to crop image data. Fallback to original image data.")
        PhotoLibraryHelpers.saveToPhotoLibrary(imageData)
        completion(.basicPhoto(thumbnail: image, imageData: imageData))
        return
      }

      PhotoLibraryHelpers.saveToPhotoLibrary(cropped.imageData)
      completion(.basicPhoto(thumbnail: cropped.thumbnail, imageData: cropped.imageData))
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
      PhotoLibraryHelpers.saveDeferredLivePhotoToPhotosLibrary(
        proxyData: deferredPhotoProxyData,
        livePhotoMovieURL: outputFileURL
      )
      completion(.livePhoto(thumbnail: thumbnail, imageData: deferredPhotoProxyData, videoData: movieData))
      return
    }

    // 일반 라이브 포토
    if let lastStillImageData = self.lastStillImageData,
      let lastThumbnailImage = self.lastThumbnailImage,
      let movieData = try? Data(contentsOf: outputFileURL)
    {
      logger.info("Live Photo: Saving standard live photo (Movie delegate).")
      PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(
        stillImageData: lastStillImageData,
        livePhotoMovieURL: outputFileURL
      )
      completion(.livePhoto(thumbnail: lastThumbnailImage, imageData: lastStillImageData, videoData: movieData))
      return
    }
  }
}

extension CameraDelegate {
  private func croppedImageData(
    from imageData: Data,
    targetRatio: CGFloat
  ) -> (thumbnail: UIImage, imageData: Data)? {
    guard let image = UIImage(data: imageData) else { return nil }
    let sourceSize = image.size
    let sourceRatio = sourceSize.width / sourceSize.height

    let cropRect: CGRect
    if sourceRatio > targetRatio {
      let targetWidth = sourceSize.height * targetRatio
      let x = (sourceSize.width - targetWidth) / 2.0
      cropRect = CGRect(x: x, y: 0, width: targetWidth, height: sourceSize.height)
    } else {
      let targetHeight = sourceSize.width / targetRatio
      let y = (sourceSize.height - targetHeight) / 2.0
      cropRect = CGRect(x: 0, y: y, width: sourceSize.width, height: targetHeight)
    }
    
    guard let cgImage = image.cgImage?.cropping(to: cropRect.integral) else { return nil }
    
    let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    
    guard let croppedData = croppedImage.jpegData(compressionQuality: 1.0) else { return nil }
    
    return (thumbnail: croppedImage, imageData: croppedData)
  }
}
