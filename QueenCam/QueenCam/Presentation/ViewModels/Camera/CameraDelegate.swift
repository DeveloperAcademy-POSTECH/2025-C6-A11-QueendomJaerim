import AVFoundation
import OSLog
import Photos
import UIKit

nonisolated final class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let logger = QueenLogger(category: "CameraDelegate")
  private let isCameraPosition: AVCaptureDevice.Position
  private let aspectRatio: PhotoAspectRatio
  private let aspectRatioCroppingService: PhotoAspectRatioCroppingServiceProtocol

  private let photoOutputProcessor: ((PhotoOuput) -> PhotoOuput?)?
  private let completion: ((PhotoOuput?, [PhotoOuput]) -> Void)
  private var lastThumbnailImage: UIImage?
  private var lastStillImageData: Data?
  private var deferredPhotoProxyData: Data?
  private var livePhotoMovieURL: URL?
  private var isLivePhotoMovieFailed = false
  private var isLivePhotoSaved = false

  private var isLivePhoto: Bool = false
  private var willCaptureLivePhoto: (() -> Void)?
  private var didFinishRecordingLivePhotoMovie: (() -> Void)?
  private var didFinishLivePhotoMovie: (() -> Void)?

  init(
    isCameraPosition: AVCaptureDevice.Position,
    aspectRatio: PhotoAspectRatio,
    aspectRatioCroppingService: PhotoAspectRatioCroppingServiceProtocol,
    willCaptureLivePhoto: (() -> Void)? = nil,
    didFinishRecordingLivePhotoMovie: (() -> Void)? = nil,
    didFinishLivePhotoMovie: (() -> Void)? = nil,
    photoOutputProcessor: ((PhotoOuput) -> PhotoOuput?)? = nil,
    completion: @escaping (PhotoOuput?, [PhotoOuput]) -> Void
  ) {
    self.isCameraPosition = isCameraPosition
    self.aspectRatio = aspectRatio
    self.aspectRatioCroppingService = aspectRatioCroppingService
    self.willCaptureLivePhoto = willCaptureLivePhoto
    self.didFinishRecordingLivePhotoMovie = didFinishRecordingLivePhotoMovie
    self.didFinishLivePhotoMovie = didFinishLivePhotoMovie
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
      saveLivePhotoIfReady()
    } else {
      saveDeferredBasicPhoto(imageData: imageData)
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
      Task {
        await saveBasicPhoto(imageData: imageData, thumbnail: image)
      }
    } else {
      saveLivePhotoIfReady()
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
    didFinishLivePhotoMovie?()

    guard error == nil else {
      logger.error("Error capturing Live Photo movie: \(error)")
      isLivePhotoMovieFailed = true
      saveLivePhotoIfReady()
      return
    }

    self.livePhotoMovieURL = outputFileURL
    saveLivePhotoIfReady()
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishRecordingLivePhotoMovieForEventualFileAt outputFileURL: URL,
    resolvedSettings: AVCaptureResolvedPhotoSettings
  ) {
    didFinishRecordingLivePhotoMovie?()
  }

  /// 촬영마다 맨 마지막에 오는 콜백이다. 영상이 끝내 오지 않거나 읽을 수 없어 저장하지 못했으면 정지 사진이라도 남긴다.
  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
    error: (any Error)?
  ) {
    guard isLivePhoto, !isLivePhotoSaved else { return }

    isLivePhotoMovieFailed = true
    saveLivePhotoIfReady()

    // 정지 사진도 없이 촬영이 끝났다. 완료를 알려야 셔터 잠금 기록과 delegate가 남지 않는다.
    guard !isLivePhotoSaved else { return }
    logger.error("[LivePhoto] 저장할 사진 없이 촬영 종료")
    completion(nil, [])
  }
}

/// 저장·썸네일·전송에 쓸 사진. `separateOriginal`은 합성본과 따로 저장·전송할 기본본이다.
nonisolated struct ProcessedOutputs {
  let final: PhotoOuput
  let separateOriginal: PhotoOuput?
}

// 비율 적용은 자르기 실패 시 원본 사용 규칙을 단위 테스트로 확인하기 위해 private으로 두지 않는다.
nonisolated extension CameraDelegate {
  /// 셔터 순간의 비율로 자른 사진을 기본본으로 쓴다. 자르지 못하면 원본을 그대로 쓴다.
  /// Live Photo는 사진과 영상을 함께 잘라야 하므로 `applyAspectRatio(toLivePhotoImageData:)`에서 다룬다.
  func applyAspectRatio(to photoOutput: PhotoOuput) -> PhotoOuput {
    guard case .basicPhoto(let thumbnail, let imageData) = photoOutput else { return photoOutput }

    guard let croppedData = aspectRatioCroppingService.crop(imageData: imageData, to: aspectRatio) else {
      logger.error("[AspectRatio] \(aspectRatio.rawValue) 촬영 → 자르기 실패, 원본 저장")
      return photoOutput
    }

    guard croppedData != imageData else { return photoOutput }

    return .basicPhoto(thumbnail: UIImage(data: croppedData) ?? thumbnail, imageData: croppedData)
  }

  /// 펜 합성이 켜져 있으면 합성본이 최종본이고 기본본은 따로 저장·전송한다.
  /// 합성이 없거나 실패하면 기본본 한 장만 최종본으로 쓴다.
  func resolveOutputs(for original: PhotoOuput) -> ProcessedOutputs {
    guard let photoOutputProcessor else { return ProcessedOutputs(final: original, separateOriginal: nil) }

    guard let processed = photoOutputProcessor(original) else {
      logger.error("[PenComposite] 펜 합성 실패 → 기본본 한 장만 저장·전송")
      return ProcessedOutputs(final: original, separateOriginal: nil)
    }

    return ProcessedOutputs(final: processed, separateOriginal: original)
  }

  /// 최종본 앞에 기본본이 있으면 함께 상대에게 보낸다.
  func sendOutputs(_ outputs: ProcessedOutputs) -> [PhotoOuput] {
    guard let separateOriginal = outputs.separateOriginal else { return [outputs.final] }
    return [separateOriginal, outputs.final]
  }

  /// Live Photo의 사진과 영상을 셔터 순간의 비율로 함께 자른다. 하나라도 자르지 못하면 짝이 깨지지 않게 원본 쌍을 쓴다.
  /// 원본 영상을 읽지 못하면 nil을 돌려준다.
  func applyAspectRatio(
    toLivePhotoImageData imageData: Data,
    thumbnail: UIImage,
    livePhotoMovieURL: URL
  ) async -> (photoOutput: PhotoOuput, livePhotoMovieURL: URL)? {
    guard let croppedImageData = aspectRatioCroppingService.crop(imageData: imageData, to: aspectRatio) else {
      logger.error("[AspectRatio] Live \(aspectRatio.rawValue) 촬영 → 사진 자르기 실패, 원본 쌍 저장")
      return originalLivePhoto(imageData: imageData, thumbnail: thumbnail, livePhotoMovieURL: livePhotoMovieURL)
    }

    guard let croppedMovieURL = await aspectRatioCroppingService.crop(livePhotoMovieURL: livePhotoMovieURL, to: aspectRatio)
    else {
      logger.error("[AspectRatio] Live \(aspectRatio.rawValue) 촬영 → 영상 자르기 실패, 원본 쌍 저장")
      return originalLivePhoto(imageData: imageData, thumbnail: thumbnail, livePhotoMovieURL: livePhotoMovieURL)
    }

    guard croppedMovieURL != livePhotoMovieURL else {
      return originalLivePhoto(imageData: imageData, thumbnail: thumbnail, livePhotoMovieURL: livePhotoMovieURL)
    }

    guard let croppedMovieData = try? Data(contentsOf: croppedMovieURL) else {
      logger.error("[AspectRatio] Live \(aspectRatio.rawValue) 촬영 → 자른 영상 읽기 실패, 원본 쌍 저장")
      try? FileManager.default.removeItem(at: croppedMovieURL)
      return originalLivePhoto(imageData: imageData, thumbnail: thumbnail, livePhotoMovieURL: livePhotoMovieURL)
    }

    // 사진 보관함에는 자른 영상 파일이 옮겨지므로 쓰지 않는 원본 영상 파일을 지운다.
    try? FileManager.default.removeItem(at: livePhotoMovieURL)

    return (
      .livePhoto(
        thumbnail: UIImage(data: croppedImageData) ?? thumbnail,
        imageData: croppedImageData,
        videoData: croppedMovieData
      ),
      croppedMovieURL
    )
  }
}

nonisolated extension CameraDelegate {
  /// 사진과 영상은 어느 순서로든 오므로 조각이 올 때마다 부른다. 둘 다 있으면 Live로 저장하고, 영상이 실패했으면 정지 사진만 저장한다.
  private func saveLivePhotoIfReady() {
    guard !isLivePhotoSaved else { return }

    guard !isLivePhotoMovieFailed else {
      saveStillPhotoOnly()
      return
    }

    guard let livePhotoMovieURL = self.livePhotoMovieURL else { return }

    // 지연 처리된 라이브 포토
    if let deferredPhotoProxyData = self.deferredPhotoProxyData,
      let movieData = try? Data(contentsOf: livePhotoMovieURL),
      let thumbnail = UIImage(data: deferredPhotoProxyData)
    {
      isLivePhotoSaved = true
      saveDeferredLivePhoto(
        .livePhoto(thumbnail: thumbnail, imageData: deferredPhotoProxyData, videoData: movieData),
        livePhotoMovieURL: livePhotoMovieURL
      )
      return
    }

    // 비율을 적용하는 라이브 포토. 4:3은 자를 것이 없어 아래 일반 경로를 그대로 쓴다.
    if aspectRatio != .ratio4x3,
      let lastStillImageData = self.lastStillImageData,
      let lastThumbnailImage = self.lastThumbnailImage
    {
      isLivePhotoSaved = true
      logger.info("Live Photo: Saving \(aspectRatio.rawValue) live photo.")
      Task {
        await saveLivePhotoInAspectRatio(
          imageData: lastStillImageData,
          thumbnail: lastThumbnailImage,
          livePhotoMovieURL: livePhotoMovieURL
        )
      }
      return
    }

    // 일반 라이브 포토
    if let lastStillImageData = self.lastStillImageData,
      let lastThumbnailImage = self.lastThumbnailImage,
      let movieData = try? Data(contentsOf: livePhotoMovieURL)
    {
      isLivePhotoSaved = true
      saveStandardLivePhoto(
        .livePhoto(thumbnail: lastThumbnailImage, imageData: lastStillImageData, videoData: movieData),
        livePhotoMovieURL: livePhotoMovieURL
      )
    }
  }

  private func saveDeferredLivePhoto(_ originalPhotoOutput: PhotoOuput, livePhotoMovieURL: URL) {
    logger.info("Live Photo: Saving deferred live photo.")
    let outputs = resolveOutputs(for: originalPhotoOutput)
    let photoOutput = outputs.final
    saveOriginalIfNeeded(outputs.separateOriginal, isDeferredLivePhoto: true)
    PhotoLibraryHelpers.saveDeferredLivePhotoToPhotosLibrary(
      proxyData: photoOutput.imageData,
      livePhotoMovieURL: livePhotoMovieURL
    )
    completion(photoOutput, sendOutputs(outputs))
  }

  private func saveStandardLivePhoto(_ originalPhotoOutput: PhotoOuput, livePhotoMovieURL: URL) {
    logger.info("Live Photo: Saving standard live photo.")
    let outputs = resolveOutputs(for: originalPhotoOutput)
    let photoOutput = outputs.final
    saveOriginalIfNeeded(outputs.separateOriginal)
    PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(
      stillImageData: photoOutput.imageData,
      livePhotoMovieURL: livePhotoMovieURL
    )
    completion(photoOutput, sendOutputs(outputs))
  }

  private func saveStillPhotoOnly() {
    if let deferredPhotoProxyData = self.deferredPhotoProxyData {
      isLivePhotoSaved = true
      logger.error("[LivePhoto] 영상 녹화 실패 → 정지 사진만 저장")
      saveDeferredBasicPhoto(imageData: deferredPhotoProxyData)
    } else if let lastStillImageData = self.lastStillImageData,
      let lastThumbnailImage = self.lastThumbnailImage
    {
      isLivePhotoSaved = true
      logger.error("[LivePhoto] 영상 녹화 실패 → 정지 사진만 저장")
      Task {
        await saveBasicPhoto(imageData: lastStillImageData, thumbnail: lastThumbnailImage)
      }
    }
  }

  private func saveDeferredBasicPhoto(imageData: Data) {
    let originalPhotoOutput = applyAspectRatio(
      to: PhotoOuput.basicPhoto(thumbnail: UIImage(data: imageData) ?? .init(), imageData: imageData)
    )
    let outputs = resolveOutputs(for: originalPhotoOutput)
    let photoOutput = outputs.final
    saveOriginalIfNeeded(outputs.separateOriginal, isDeferredPhoto: true)
    PhotoLibraryHelpers.saveProxyToPhotoLibrary(photoOutput.imageData)
    completion(photoOutput, sendOutputs(outputs))
  }

  /// 사진 자르기와 펜 합성이 화면을 멈추지 않게 카메라 콜백 스레드와 상관없이 백그라운드에서 처리하고 저장한다.
  @concurrent
  private func saveBasicPhoto(imageData: Data, thumbnail: UIImage) async {
    let originalPhotoOutput = applyAspectRatio(to: PhotoOuput.basicPhoto(thumbnail: thumbnail, imageData: imageData))
    let outputs = resolveOutputs(for: originalPhotoOutput)
    let photoOutput = outputs.final
    saveOriginalIfNeeded(outputs.separateOriginal)
    PhotoLibraryHelpers.saveToPhotoLibrary(photoOutput.imageData)
    completion(photoOutput, sendOutputs(outputs))
  }

  /// 영상 자르기는 오래 걸리므로 카메라 콜백 스레드와 상관없이 백그라운드에서 자르고 저장한다.
  @concurrent
  private func saveLivePhotoInAspectRatio(imageData: Data, thumbnail: UIImage, livePhotoMovieURL: URL) async {
    guard
      let livePhoto = await applyAspectRatio(
        toLivePhotoImageData: imageData,
        thumbnail: thumbnail,
        livePhotoMovieURL: livePhotoMovieURL
      )
    else {
      logger.error("[AspectRatio] Live \(aspectRatio.rawValue) 촬영 → 원본 영상 읽기 실패, 정지 사진만 저장")
      await saveBasicPhoto(imageData: imageData, thumbnail: thumbnail)
      return
    }

    let outputs = resolveOutputs(for: livePhoto.photoOutput)
    let photoOutput = outputs.final
    saveOriginalIfNeeded(outputs.separateOriginal)
    PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(
      stillImageData: photoOutput.imageData,
      livePhotoMovieURL: livePhoto.livePhotoMovieURL
    )
    completion(photoOutput, sendOutputs(outputs))
  }

  private func originalLivePhoto(
    imageData: Data,
    thumbnail: UIImage,
    livePhotoMovieURL: URL
  ) -> (photoOutput: PhotoOuput, livePhotoMovieURL: URL)? {
    guard let movieData = try? Data(contentsOf: livePhotoMovieURL) else { return nil }

    return (.livePhoto(thumbnail: thumbnail, imageData: imageData, videoData: movieData), livePhotoMovieURL)
  }

  private func saveOriginalIfNeeded(
    _ photoOutput: PhotoOuput?,
    isDeferredPhoto: Bool = false,
    isDeferredLivePhoto: Bool = false
  ) {
    guard let photoOutput else { return }

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
