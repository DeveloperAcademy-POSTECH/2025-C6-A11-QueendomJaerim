import AVFoundation
import OSLog
import Photos
import UIKit

// MARK: - Live Photo Handlers
extension CameraDelegate {
  /// 최종 저장에 사용할 movie URL을 결정한다.
  /// 가공본이 유효하고 pair 검증까지 통과하면 가공본, 아니면 원본을 사용한다.
  func resolveLivePhotoMovieURL(originalMovieURL: URL, selectedRatio: PhotoAspectRatio) async -> URL {
    if let processedMovieURL = await processLivePhotoMovieURL(originalMovieURL: originalMovieURL, selectedRatio: selectedRatio) {
      if (try? Data(contentsOf: processedMovieURL)) != nil {
        let isPairCompatible = await isLivePhotoPairCompatible(
          originalMovieURL: originalMovieURL,
          processedMovieURL: processedMovieURL
        )

        if isPairCompatible {
          return processedMovieURL
        }

        logger.warning("Processed movie metadata is not compatible with original live pair. Fallback to original movie.")
        return originalMovieURL
      }

      logger.warning("Processed movie data is unavailable. Fallback to original movie.")
    }
    return originalMovieURL
  }
}

extension CameraDelegate {
  private struct LiveMovieSource {
    let asset: AVURLAsset
    let videoTrack: AVAssetTrack
    let duration: CMTime
    let assetMetadata: [AVMetadataItem]
    let naturalSize: CGSize
    let preferredTransform: CGAffineTransform
    let nominalFrameRate: Float
  }

  private struct LiveMovieCropContext {
    let transformedRect: CGRect
    let orientedSize: CGSize
    let targetRatio: CGFloat
    let cropRect: CGRect
  }

  private struct LiveMovieCompositionContext {
    let composition: AVMutableComposition
    let compositionVideoTrack: AVCompositionTrack
  }
}

extension CameraDelegate {
  /// 라이브 movie를 선택 비율에 맞게 가공(export)한다.
  /// 실패하면 nil을 반환하고 상위에서 원본 movie로 fallback한다.
  private func processLivePhotoMovieURL(originalMovieURL: URL, selectedRatio: PhotoAspectRatio) async -> URL? {
    if selectedRatio == .ratio4x3 {
      return originalMovieURL
    }

    guard let source = await loadLiveMovieSource(from: originalMovieURL) else {
      return nil
    }

    let cropContext = makeLiveMovieCropContext(
      naturalSize: source.naturalSize,
      preferredTransform: source.preferredTransform,
      selectedRatio: selectedRatio.value
    )

    guard let compositionContext = await makeLiveMovieCompositionContext(
      asset: source.asset,
      videoTrack: source.videoTrack,
      duration: source.duration
    ) else {
      return nil
    }

    let videoComposition = makeLiveMovieVideoComposition(
      preferredTransform: source.preferredTransform,
      nominalFrameRate: source.nominalFrameRate,
      transformedRect: cropContext.transformedRect,
      cropRect: cropContext.cropRect,
      compositionVideoTrack: compositionContext.compositionVideoTrack
    )

    return await exportLiveMovie(
      composition: compositionContext.composition,
      videoComposition: videoComposition,
      assetMetadata: source.assetMetadata
    )
  }

  /// 원본 live movie에서 가공에 필요한 기본 정보를 읽어온다.
  private func loadLiveMovieSource(from movieURL: URL) async -> LiveMovieSource? {
    let asset = AVURLAsset(url: movieURL)

    guard let videoTracks = try? await asset.loadTracks(withMediaType: .video),
      let videoTrack = videoTracks.first
    else {
      logger.error("Live movie process failed: video track not found.")
      return nil
    }

    guard let duration = try? await asset.load(.duration),
      let assetMetadata = try? await asset.load(.metadata),
      let naturalSize = try? await videoTrack.load(.naturalSize),
      let preferredTransform = try? await videoTrack.load(.preferredTransform),
      let nominalFrameRate = try? await videoTrack.load(.nominalFrameRate)
    else {
      logger.error("Live movie process failed: failed to load live movie source metadata.")
      return nil
    }

    return LiveMovieSource(
      asset: asset,
      videoTrack: videoTrack,
      duration: duration,
      assetMetadata: assetMetadata,
      naturalSize: naturalSize,
      preferredTransform: preferredTransform,
      nominalFrameRate: nominalFrameRate
    )
  }

  /// 실제 표시 방향 기준 크기를 구한 뒤, movie에 적용할 crop rect를 계산한다.
  private func makeLiveMovieCropContext(
    naturalSize: CGSize,
    preferredTransform: CGAffineTransform,
    selectedRatio: CGFloat
  ) -> LiveMovieCropContext {
    let transformedRect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
    let orientedSize = CGSize(width: abs(transformedRect.width), height: abs(transformedRect.height))
    let targetRatio = normalizedTargetRatio(
      selectedRatio: selectedRatio,
      sourceSize: orientedSize
    )
    let cropRect = centerCropRect(sourceSize: orientedSize, targetRatio: targetRatio)

    logger.debug(
      "Live movie crop context: orientedSize=\(orientedSize.debugDescription), targetRatio=\(targetRatio), cropRect=\(cropRect.debugDescription)"
    )

    return LiveMovieCropContext(
      transformedRect: transformedRect,
      orientedSize: orientedSize,
      targetRatio: targetRatio,
      cropRect: cropRect
    )
  }

  /// video/audio/metadata 트랙을 새 composition에 다시 담는다.
  private func makeLiveMovieCompositionContext(
    asset: AVURLAsset,
    videoTrack: AVAssetTrack,
    duration: CMTime
  ) async -> LiveMovieCompositionContext? {
    let composition = AVMutableComposition()

    guard
      let compositionVideoTrack = composition.addMutableTrack(
        withMediaType: .video,
        preferredTrackID: kCMPersistentTrackID_Invalid
      )
    else {
      logger.error("Live movie process failed: failed to add composition video track.")
      return nil
    }

    do {
      try compositionVideoTrack.insertTimeRange(
        CMTimeRange(start: .zero, duration: duration),
        of: videoTrack,
        at: .zero
      )
    } catch {
      logger.error("Live movie process failed: failed to insert video track. \(error.localizedDescription)")
      return nil
    }

    let audioTracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
    if let audioTrack = audioTracks.first,
      let compositionAudioTrack = composition.addMutableTrack(
        withMediaType: .audio,
        preferredTrackID: kCMPersistentTrackID_Invalid
      )
    {
      try? compositionAudioTrack.insertTimeRange(
        CMTimeRange(start: .zero, duration: duration),
        of: audioTrack,
        at: .zero
      )
    }

    let metadataTracks = (try? await asset.loadTracks(withMediaType: .metadata)) ?? []
    for metadataTrack in metadataTracks {
      if let compositionMetadataTrack = composition.addMutableTrack(
        withMediaType: .metadata,
        preferredTrackID: kCMPersistentTrackID_Invalid
      ) {
        try? compositionMetadataTrack.insertTimeRange(
          CMTimeRange(start: .zero, duration: duration),
          of: metadataTrack,
          at: .zero
        )
      }
    }

    logger.debug("Live movie composition created.")

    return LiveMovieCompositionContext(
      composition: composition,
      compositionVideoTrack: compositionVideoTrack
    )
  }

  /// crop rect에 맞게 video를 렌더링할 transform과 video composition을 구성한다.
  private func makeLiveMovieVideoComposition(
    preferredTransform: CGAffineTransform,
    nominalFrameRate: Float,
    transformedRect: CGRect,
    cropRect: CGRect,
    compositionVideoTrack: AVCompositionTrack
  ) -> AVVideoComposition {
    let translatedTransform = preferredTransform.concatenating(
      CGAffineTransform(
        translationX: -transformedRect.origin.x - cropRect.origin.x,
        y: -transformedRect.origin.y - cropRect.origin.y
      )
    )

    var layerInstructionConfiguration = AVVideoCompositionLayerInstruction.Configuration(trackID: compositionVideoTrack.trackID)
    layerInstructionConfiguration.setTransform(translatedTransform, at: .zero)
    let layerInstruction = AVVideoCompositionLayerInstruction(configuration: layerInstructionConfiguration)

    var instructionConfiguration = AVVideoCompositionInstruction.Configuration()
    instructionConfiguration.timeRange = compositionVideoTrack.timeRange
    instructionConfiguration.layerInstructions = [layerInstruction]
    let instruction = AVVideoCompositionInstruction(configuration: instructionConfiguration)

    var videoCompositionConfiguration = AVVideoComposition.Configuration()
    videoCompositionConfiguration.instructions = [instruction]
    videoCompositionConfiguration.renderSize = cropRect.integral.size

    let frameRate = nominalFrameRate > 0 ? nominalFrameRate : 30
    videoCompositionConfiguration.frameDuration = CMTime(
      value: 1,
      timescale: CMTimeScale(frameRate.rounded())
    )
    return AVVideoComposition(configuration: videoCompositionConfiguration)
  }

  /// 최종 crop된 live movie를 새 .mov 파일로 export한다.
  private func exportLiveMovie(
    composition: AVMutableComposition,
    videoComposition: AVVideoComposition,
    assetMetadata: [AVMetadataItem]
  ) async -> URL? {
    let outputURL = makeLiveMovieOutputURL()
    if FileManager.default.fileExists(atPath: outputURL.path) {
      try? FileManager.default.removeItem(at: outputURL)
    }

    guard
      let exportSession = AVAssetExportSession(
        asset: composition,
        presetName: AVAssetExportPresetHighestQuality
      )
    else {
      logger.error("Live movie process failed: failed to create export session.")
      return nil
    }

    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mov
    exportSession.videoComposition = videoComposition
    exportSession.metadata = assetMetadata
    exportSession.shouldOptimizeForNetworkUse = false

    do {
      try await exportSession.export(to: outputURL, as: .mov)
      logger.info("Live movie process: export success. outputURL=\(outputURL.path)")
      return outputURL
    } catch {
      logger.error("Live movie process failed: export failed. \(error.localizedDescription)")
      return nil
    }
  }

  /// 가공된 live movie를 임시 저장할 URL을 생성한다.
  private func makeLiveMovieOutputURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("live_movie_\(UUID().uuidString)")
      .appendingPathExtension("mov")
  }

  /// 원본/가공 movie의 Live Photo content identifier 일치 여부를 검증한다.
  private func isLivePhotoPairCompatible(originalMovieURL: URL, processedMovieURL: URL) async -> Bool {
    let originalContentIdentifier = await livePhotoContentIdentifier(from: originalMovieURL)
    let processedContentIdentifier = await livePhotoContentIdentifier(from: processedMovieURL)

    guard
      let originalContentIdentifier,
      let processedContentIdentifier
    else {
      logger.warning("Live movie metadata check failed: content identifier is missing.")
      return false
    }

    if originalContentIdentifier != processedContentIdentifier {
      logger.warning("Live movie metadata check failed: content identifier mismatch.")
      return false
    }

    return true
  }

  /// movie 메타데이터에서 Live Photo content identifier를 추출한다.
  private func livePhotoContentIdentifier(from movieURL: URL) async -> String? {
    let asset = AVURLAsset(url: movieURL)
    let metadata = (try? await asset.load(.metadata)) ?? []

    let contentIdentifierItem = AVMetadataItem.metadataItems(
      from: metadata,
      filteredByIdentifier: .quickTimeMetadataContentIdentifier
    ).first

    guard let contentIdentifierItem else { return nil }
    return try? await contentIdentifierItem.load(.stringValue)
  }
}
