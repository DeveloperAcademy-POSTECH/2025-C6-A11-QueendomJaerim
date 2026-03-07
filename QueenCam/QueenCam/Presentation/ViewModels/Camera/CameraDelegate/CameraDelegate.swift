import AVFoundation
import OSLog
import Photos
import UIKit

final class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  let logger = QueenLogger(category: "CameraDelegate")
  private let isCameraPosition: AVCaptureDevice.Position
  let selectedPhotoAspectRatio: PhotoAspectRatio

  let completion: ((PhotoOuput?) -> Void)
  var lastThumbnailImage: UIImage?
  var lastStillImageData: Data?
  var deferredPhotoProxyData: Data?
  var livePhotoMovieURL: URL?

  var isLivePhoto: Bool = false
  var willCaptureLivePhoto: (() -> Void)?

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
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraDelegate {
  /// 촬영 시작 직전에 호출된다.
  /// 현재 요청이 Live Photo인지 판별하고 필요 시 라이브 촬영 UI 콜백을 전달한다.
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
    /// Deferred 프록시 데이터 수신 지점.
    /// 일반 사진은 즉시 저장 처리, 라이브는 still(proxy) 데이터를 가공/보관한다.
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
      let processedLiveStillData = processLivePhotoStillImageData(imageData: imageData)
      // 라이브 deferred는 여기서 저장하지 않고 movie delegate에서 최종 저장한다.
      self.deferredPhotoProxyData = processedLiveStillData
    } else {
      handleBasicPhoto(
        imageData: imageData,
        photoSaveType: .proxy,
        cropFailureMessage: "Deferred proxy crop failed. Fallback to original image data."
      )
    }
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: (any Error)?
  ) {
    /// still 이미지 수신 지점.
    /// 일반 사진은 여기서 저장까지 완료하고, 라이브는 still만 가공해서 임시 보관한다.
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

    if isLivePhoto {
      let processedLiveStillData = processLivePhotoStillImageData(imageData: imageData)
      lastThumbnailImage = UIImage(data: processedLiveStillData) ?? image
      lastStillImageData = processedLiveStillData
    } else {
      lastThumbnailImage = image
      lastStillImageData = imageData
      handleBasicPhoto(
        imageData: imageData,
        photoSaveType: .basic,
        cropFailureMessage: "Failed to crop image data. Fallback to original image data."
      )
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
    /// 라이브 movie 수신 지점.
    /// deferred 경로와 standard 경로를 분기해 최종 Live Photo 저장을 수행한다.

    guard error == nil else {
      logger.error("Error capturing Live Photo movie: \(error)")
      completion(nil)
      resetCaptureState()
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
      resetCaptureState()
      return
    }

    // 일반 라이브 포토
    if let lastStillImageData = self.lastStillImageData,
      let lastThumbnailImage = self.lastThumbnailImage
    {
      Task { [weak self] in
        guard let self else { return }

        let finalMovieURL = await resolveLivePhotoMovieURL(originalMovieURL: outputFileURL, selectedRatio: selectedPhotoAspectRatio)

        guard let movieData = try? Data(contentsOf: finalMovieURL) else {
          completion(nil)
          resetCaptureState()
          return
        }

        logger.info("Live Photo: Saving standard live photo (Movie delegate).")
        PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(
          stillImageData: lastStillImageData,
          livePhotoMovieURL: finalMovieURL
        )
        completion(.livePhoto(thumbnail: lastThumbnailImage, imageData: lastStillImageData, videoData: movieData))
        resetCaptureState()
      }
    }
  }
}
