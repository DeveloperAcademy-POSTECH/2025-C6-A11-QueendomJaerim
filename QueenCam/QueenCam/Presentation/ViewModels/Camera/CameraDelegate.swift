import AVFoundation
import OSLog
import Photos
import UIKit

nonisolated final class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let logger = QueenLogger(category: "CameraDelegate")
  private let isCameraPosition: AVCaptureDevice.Position
  private let aspectRatio: PhotoAspectRatio
  private let aspectRatioCroppingService: PhotoAspectRatioCroppingServiceProtocol

  private let photoOutputProcessor: ((PhotoOuput) -> PhotoOuput)?
  private let completion: ((PhotoOuput?, [PhotoOuput]) -> Void)
  private var lastThumbnailImage: UIImage?
  private var lastStillImageData: Data?
  private var deferredPhotoProxyData: Data?
  private var livePhotoMovieURL: URL?

  private var isLivePhoto: Bool = false
  private var willCaptureLivePhoto: (() -> Void)?

  init(
    isCameraPosition: AVCaptureDevice.Position,
    aspectRatio: PhotoAspectRatio,
    aspectRatioCroppingService: PhotoAspectRatioCroppingServiceProtocol,
    willCaptureLivePhoto: (() -> Void)? = nil,
    photoOutputProcessor: ((PhotoOuput) -> PhotoOuput)? = nil,
    completion: @escaping (PhotoOuput?, [PhotoOuput]) -> Void
  ) {
    self.isCameraPosition = isCameraPosition
    self.aspectRatio = aspectRatio
    self.aspectRatioCroppingService = aspectRatioCroppingService
    self.willCaptureLivePhoto = willCaptureLivePhoto
    self.photoOutputProcessor = photoOutputProcessor
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
      completion(nil, [])
      return
    }

    guard let deferredPhotoProxy,
      let imageData = deferredPhotoProxy.fileDataRepresentation()
    else {
      logger.error("Deferred proxy is nil or no data")
      completion(nil, [])
      return
    }

    if isLivePhoto {
      self.deferredPhotoProxyData = imageData
      if let livePhotoMovieURL = self.livePhotoMovieURL,
        let movieData = try? Data(contentsOf: livePhotoMovieURL),
        let thumbnail = UIImage(data: imageData)
      {
        logger.info("Live Photo: Saving deferred live photo (Proxy delegate).")
        let originalPhotoOutput = PhotoOuput.livePhoto(thumbnail: thumbnail, imageData: imageData, videoData: movieData)
        let photoOutput = process(originalPhotoOutput)
        saveOriginalIfNeeded(originalPhotoOutput, isDeferredLivePhoto: true)
        PhotoLibraryHelpers.saveDeferredLivePhotoToPhotosLibrary(
          proxyData: photoOutput.imageData,
          livePhotoMovieURL: livePhotoMovieURL
        )

        completion(photoOutput, sendOutputs(original: originalPhotoOutput, processed: photoOutput))
      }
    } else {
      let originalPhotoOutput = applyAspectRatio(
        to: PhotoOuput.basicPhoto(thumbnail: UIImage(data: imageData) ?? .init(), imageData: imageData)
      )
      let photoOutput = process(originalPhotoOutput)
      saveOriginalIfNeeded(originalPhotoOutput, isDeferredPhoto: true)
      PhotoLibraryHelpers.saveProxyToPhotoLibrary(photoOutput.imageData)
      completion(photoOutput, sendOutputs(original: originalPhotoOutput, processed: photoOutput))
    }
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: (any Error)?
  ) {
    guard error == nil else {
      logger.error("Error while capturing photo")
      completion(nil, [])
      return
    }

    guard
      let imageData = photo.fileDataRepresentation(),
      let image = UIImage(data: imageData)
    else {
      logger.error("Image not fetched.")
      completion(nil, [])
      return
    }

    lastThumbnailImage = image
    lastStillImageData = imageData

    if !isLivePhoto {
      let originalPhotoOutput = applyAspectRatio(to: PhotoOuput.basicPhoto(thumbnail: image, imageData: imageData))
      let photoOutput = process(originalPhotoOutput)
      saveOriginalIfNeeded(originalPhotoOutput)
      PhotoLibraryHelpers.saveToPhotoLibrary(photoOutput.imageData)
      completion(photoOutput, sendOutputs(original: originalPhotoOutput, processed: photoOutput))
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
      completion(nil, [])
      return
    }

    self.livePhotoMovieURL = outputFileURL

    // 지연 처리된 라이브 포토
    if let deferredPhotoProxyData = self.deferredPhotoProxyData,
      let movieData = try? Data(contentsOf: outputFileURL),
      let thumbnail = UIImage(data: deferredPhotoProxyData)
    {
      logger.info("Live Photo: Saving deferred live photo (Movie delegate).")
      let originalPhotoOutput = PhotoOuput.livePhoto(
        thumbnail: thumbnail,
        imageData: deferredPhotoProxyData,
        videoData: movieData
      )
      let photoOutput = process(originalPhotoOutput)
      saveOriginalIfNeeded(originalPhotoOutput, isDeferredLivePhoto: true)
      PhotoLibraryHelpers.saveDeferredLivePhotoToPhotosLibrary(
        proxyData: photoOutput.imageData,
        livePhotoMovieURL: outputFileURL
      )
      completion(photoOutput, sendOutputs(original: originalPhotoOutput, processed: photoOutput))
      return
    }

    // 일반 라이브 포토
    if let lastStillImageData = self.lastStillImageData,
      let lastThumbnailImage = self.lastThumbnailImage,
      let movieData = try? Data(contentsOf: outputFileURL)
    {
      logger.info("Live Photo: Saving standard live photo (Movie delegate).")
      let originalPhotoOutput = PhotoOuput.livePhoto(
        thumbnail: lastThumbnailImage,
        imageData: lastStillImageData,
        videoData: movieData
      )
      let photoOutput = process(originalPhotoOutput)
      saveOriginalIfNeeded(originalPhotoOutput)
      PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(
        stillImageData: photoOutput.imageData,
        livePhotoMovieURL: outputFileURL
      )
      completion(photoOutput, sendOutputs(original: originalPhotoOutput, processed: photoOutput))
      return
    }
  }
}

// 비율 적용은 자르기 실패 시 원본 사용 규칙을 단위 테스트로 확인하기 위해 private으로 두지 않는다.
nonisolated extension CameraDelegate {
  /// 셔터 순간의 비율로 자른 사진을 기본본으로 쓴다. 자르지 못하면 원본을 그대로 쓴다.
  /// Live Photo는 사진과 영상을 함께 잘라야 하므로 아직 원본을 유지한다.
  func applyAspectRatio(to photoOutput: PhotoOuput) -> PhotoOuput {
    guard case .basicPhoto(let thumbnail, let imageData) = photoOutput else { return photoOutput }

    let clock = ContinuousClock()
    let startedAt = clock.now
    guard let croppedData = aspectRatioCroppingService.crop(imageData: imageData, to: aspectRatio) else {
      logger.error("[AspectRatio] \(aspectRatio.rawValue) 촬영 → 자르기 실패, 원본 저장")
      return photoOutput
    }
    let elapsed = clock.now - startedAt

    let before = PhotoImageDataSummary.make(from: imageData)
    let after = PhotoImageDataSummary.make(from: croppedData)
    logger.debug(
      """
      [AspectRatio] \(PhotoImageDataSummary.verdict(ratio: aspectRatio, before: before, after: after)) \
      | before=\(before?.description ?? "unknown") \
      after=\(after?.description ?? "unknown") \
      elapsed=\(elapsed.formatted(.units(allowed: [.milliseconds])))
      """
    )

    guard croppedData != imageData else { return photoOutput }

    return .basicPhoto(thumbnail: UIImage(data: croppedData) ?? thumbnail, imageData: croppedData)
  }
}

nonisolated private extension CameraDelegate {
  func process(_ photoOutput: PhotoOuput) -> PhotoOuput {
    photoOutputProcessor?(photoOutput) ?? photoOutput
  }

  func sendOutputs(original: PhotoOuput, processed: PhotoOuput) -> [PhotoOuput] {
    guard photoOutputProcessor != nil else { return [processed] }
    return [original, processed]
  }

  func saveOriginalIfNeeded(
    _ photoOutput: PhotoOuput,
    isDeferredPhoto: Bool = false,
    isDeferredLivePhoto: Bool = false
  ) {
    guard photoOutputProcessor != nil else { return }

    switch photoOutput {
    case .basicPhoto(_, let imageData):
      if isDeferredPhoto {
        PhotoLibraryHelpers.saveProxyToPhotoLibrary(imageData)
      } else {
        PhotoLibraryHelpers.saveToPhotoLibrary(imageData)
      }

    case .livePhoto(_, let imageData, let videoData):
      if isDeferredLivePhoto {
        PhotoLibraryHelpers.saveDeferredLivePhotoToPhotosLibrary(proxyData: imageData, livePhotoMovieData: videoData)
      } else {
        PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(stillImageData: imageData, livePhotoMovieData: videoData)
      }
    }
  }
}
