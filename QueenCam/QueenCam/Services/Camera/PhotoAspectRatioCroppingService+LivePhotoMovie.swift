//
//  PhotoAspectRatioCroppingService+LivePhotoMovie.swift
//  QueenCam
//
//  Created by seungchan on 10/28/26.
//

import AVFoundation
import CoreMedia
import CoreVideo
import Foundation

// Live Photo 영상은 화면만 가운데에서 잘라 다시 쓰고, 소리·대표 사진 시점 정보·짝 식별자는 원본 그대로 옮긴다.
// 시간 정보를 원본과 같게 유지해야 사진 앱이 사진과 영상을 한 Live Photo로 묶는다.
extension PhotoAspectRatioCroppingService {
  func crop(livePhotoMovieURL: URL, to ratio: PhotoAspectRatio) async -> URL? {
    do {
      return try await Self.makeCroppedMovie(from: livePhotoMovieURL, ratio: ratio)
    } catch {
      Self.logger.error("Failed to crop Live Photo movie to \(ratio.rawValue): \(error)")
      return nil
    }
  }
}

extension PhotoAspectRatioCroppingService {
  /// 영상 쓰기 API가 콜백을 실행할 큐를 요구한다. 촬영이 끝난 파일을 다루는 후처리라 카메라 세션 큐와 나눈다.
  private static let movieCroppingQueue = DispatchQueue(label: "com.queendom.QueenCam.livePhotoMovieCroppingQueue")

  private enum MovieCroppingError: Error {
    case videoTrackNotFound
    case invalidCropRect
    case cannotAddTrack
    case readingFailed(Error?)
    case writingFailed(Error?)
  }

  /// 원본 트랙 하나를 새 파일로 옮기는 단위. 화면은 잘라서, 나머지는 그대로 옮긴다.
  /// 복사 콜백은 `movieCroppingQueue`에서만 실행되므로 읽기·쓰기 객체를 동시에 다루지 않는다.
  private struct MovieTrackCopy: @unchecked Sendable {
    let output: AVAssetReaderOutput
    let input: AVAssetWriterInput
    let append: (CMSampleBuffer) -> Bool
  }

  private enum MovieTrackCopyStatus {
    case waiting
    case finished
    case failed
  }

  private static func makeCroppedMovie(from livePhotoMovieURL: URL, ratio: PhotoAspectRatio) async throws -> URL {
    let asset = AVURLAsset(url: livePhotoMovieURL)
    guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
      throw MovieCroppingError.videoTrackNotFound
    }

    let naturalSize = try await videoTrack.load(.naturalSize)
    guard let cropRect = evenCenterCropRect(size: naturalSize, ratio: ratio) else { throw MovieCroppingError.invalidCropRect }
    guard cropRect.size != naturalSize else { return livePhotoMovieURL }

    let croppedMovieURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension(for: .quickTimeMovie)
    let reader = try AVAssetReader(asset: asset)
    let writer = try AVAssetWriter(outputURL: croppedMovieURL, fileType: .mov)
    writer.metadata = try await asset.load(.metadata)

    let videoCopy = try await makeVideoCopy(track: videoTrack, cropRect: cropRect, reader: reader, writer: writer)
    var copies = [videoCopy]
    for mediaType in [AVMediaType.audio, .metadata] {
      for track in try await asset.loadTracks(withMediaType: mediaType) {
        copies.append(try await makePassthroughCopy(track: track, mediaType: mediaType, reader: reader, writer: writer))
      }
    }

    guard reader.startReading() else { throw MovieCroppingError.readingFailed(reader.error) }
    guard writer.startWriting() else { throw MovieCroppingError.writingFailed(writer.error) }
    let timeRange = try await videoTrack.load(.timeRange)
    writer.startSession(atSourceTime: timeRange.start)

    await copyAll(copies, reader: reader)

    guard reader.status == .completed else {
      writer.cancelWriting()
      try? FileManager.default.removeItem(at: croppedMovieURL)
      throw MovieCroppingError.readingFailed(reader.error)
    }
    writer.endSession(atSourceTime: try await asset.load(.duration))
    await writer.finishWriting()
    guard writer.status == .completed else {
      try? FileManager.default.removeItem(at: croppedMovieURL)
      throw MovieCroppingError.writingFailed(writer.error)
    }

    return croppedMovieURL
  }

  /// 영상 코덱이 짝수 크기를 요구하므로 가운데 크롭 영역을 짝수로 맞춘다.
  private static func evenCenterCropRect(size: CGSize, ratio: PhotoAspectRatio) -> CGRect? {
    guard let rect = PhotoAspectRatioGeometry.centerCropRect(imageSize: size, ratio: ratio) else { return nil }

    let width = Int(rect.width) / 2 * 2
    let height = Int(rect.height) / 2 * 2
    guard width > 0, height > 0 else { return nil }

    let x = (Int(size.width) - width) / 4 * 2
    let y = (Int(size.height) - height) / 4 * 2
    return CGRect(x: x, y: y, width: width, height: height)
  }

  private static func makeVideoCopy(
    track: AVAssetTrack,
    cropRect: CGRect,
    reader: AVAssetReader,
    writer: AVAssetWriter
  ) async throws -> MovieTrackCopy {
    let formatDescription = try await track.load(.formatDescriptions).first
    let isHEVC = formatDescription.map { CMFormatDescriptionGetMediaSubType($0) == kCMVideoCodecType_HEVC } ?? false
    // HEVC Live Photo는 10비트일 수 있어 10비트로 읽고 쓴다.
    let pixelFormat = isHEVC ? kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange : kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange

    let output = AVAssetReaderTrackOutput(
      track: track,
      outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: pixelFormat]
    )
    output.alwaysCopiesSampleData = false

    let input = AVAssetWriterInput(
      mediaType: .video,
      outputSettings: try await videoOutputSettings(
        track: track,
        formatDescription: formatDescription,
        codec: isHEVC ? .hevc : .h264,
        cropRect: cropRect
      )
    )
    input.transform = try await track.load(.preferredTransform)
    input.expectsMediaDataInRealTime = false

    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: input,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
        kCVPixelBufferWidthKey as String: Int(cropRect.width),
        kCVPixelBufferHeightKey as String: Int(cropRect.height)
      ]
    )

    guard reader.canAdd(output), writer.canAdd(input) else { throw MovieCroppingError.cannotAddTrack }
    reader.add(output)
    writer.add(input)

    return MovieTrackCopy(output: output, input: input) { sampleBuffer in
      guard
        let source = CMSampleBufferGetImageBuffer(sampleBuffer),
        let pool = adaptor.pixelBufferPool,
        let destination = makePixelBuffer(from: pool),
        copyCroppedPlanes(from: source, to: destination, cropRect: cropRect)
      else { return false }

      CVBufferPropagateAttachments(source, destination)
      return adaptor.append(destination, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
    }
  }

  private static func videoOutputSettings(
    track: AVAssetTrack,
    formatDescription: CMFormatDescription?,
    codec: AVVideoCodecType,
    cropRect: CGRect
  ) async throws -> [String: Any] {
    var settings: [String: Any] = [
      AVVideoCodecKey: codec,
      AVVideoWidthKey: Int(cropRect.width),
      AVVideoHeightKey: Int(cropRect.height)
    ]

    // 잘린 면적만큼 비트레이트를 줄여 원본과 비슷한 화질·용량을 유지한다.
    let naturalSize = try await track.load(.naturalSize)
    let estimatedDataRate = try await track.load(.estimatedDataRate)
    if estimatedDataRate > 0, naturalSize.width > 0, naturalSize.height > 0 {
      let areaRatio = (cropRect.width * cropRect.height) / (naturalSize.width * naturalSize.height)
      settings[AVVideoCompressionPropertiesKey] = [AVVideoAverageBitRateKey: Int(Double(estimatedDataRate) * areaRatio)]
    }

    if let colorProperties = colorProperties(of: formatDescription) {
      settings[AVVideoColorPropertiesKey] = colorProperties
    }
    return settings
  }

  private static func colorProperties(of formatDescription: CMFormatDescription?) -> [String: Any]? {
    guard let formatDescription else { return nil }
    let extensions = CMFormatDescriptionGetExtensions(formatDescription) as? [String: Any] ?? [:]

    guard
      let primaries = extensions[kCMFormatDescriptionExtension_ColorPrimaries as String],
      let transfer = extensions[kCMFormatDescriptionExtension_TransferFunction as String],
      let matrix = extensions[kCMFormatDescriptionExtension_YCbCrMatrix as String]
    else { return nil }

    return [
      AVVideoColorPrimariesKey: primaries,
      AVVideoTransferFunctionKey: transfer,
      AVVideoYCbCrMatrixKey: matrix
    ]
  }

  private static func makePassthroughCopy(
    track: AVAssetTrack,
    mediaType: AVMediaType,
    reader: AVAssetReader,
    writer: AVAssetWriter
  ) async throws -> MovieTrackCopy {
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
    output.alwaysCopiesSampleData = false

    let input = AVAssetWriterInput(
      mediaType: mediaType,
      outputSettings: nil,
      sourceFormatHint: try await track.load(.formatDescriptions).first
    )
    input.expectsMediaDataInRealTime = false

    guard reader.canAdd(output), writer.canAdd(input) else { throw MovieCroppingError.cannotAddTrack }
    reader.add(output)
    writer.add(input)

    return MovieTrackCopy(output: output, input: input) { sampleBuffer in
      input.append(sampleBuffer)
    }
  }

  private static func makePixelBuffer(from pool: CVPixelBufferPool) -> CVPixelBuffer? {
    var pixelBuffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
    return pixelBuffer
  }

  /// Y면과 CbCr면을 각각 같은 영역만큼 줄 단위로 복사한다. 색 변환이 없어 원본 색을 그대로 유지한다.
  private static func copyCroppedPlanes(from source: CVPixelBuffer, to destination: CVPixelBuffer, cropRect: CGRect) -> Bool {
    let pixelFormat = CVPixelBufferGetPixelFormatType(source)
    guard
      CVPixelBufferGetPlaneCount(source) == 2,
      CVPixelBufferGetPixelFormatType(destination) == pixelFormat
    else { return false }

    // 8비트는 Y 1바이트·CbCr 2바이트, 10비트는 2배를 쓴다. CbCr면은 가로·세로 절반 크기다.
    let componentBytes = pixelFormat == kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange ? 2 : 1
    let planes = [(scale: 1, bytesPerPixel: componentBytes), (scale: 2, bytesPerPixel: componentBytes * 2)]

    CVPixelBufferLockBaseAddress(source, .readOnly)
    CVPixelBufferLockBaseAddress(destination, [])
    defer {
      CVPixelBufferUnlockBaseAddress(destination, [])
      CVPixelBufferUnlockBaseAddress(source, .readOnly)
    }

    for (index, plane) in planes.enumerated() {
      guard
        let sourceBase = CVPixelBufferGetBaseAddressOfPlane(source, index),
        let destinationBase = CVPixelBufferGetBaseAddressOfPlane(destination, index)
      else { return false }

      let sourceBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(source, index)
      let destinationBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(destination, index)
      let rowBytes = CVPixelBufferGetWidthOfPlane(destination, index) * plane.bytesPerPixel
      let rowCount = CVPixelBufferGetHeightOfPlane(destination, index)
      let originX = Int(cropRect.minX) / plane.scale * plane.bytesPerPixel
      let originY = Int(cropRect.minY) / plane.scale

      guard rowBytes <= destinationBytesPerRow, originX + rowBytes <= sourceBytesPerRow else { return false }

      for row in 0..<rowCount {
        memcpy(
          destinationBase.advanced(by: row * destinationBytesPerRow),
          sourceBase.advanced(by: (originY + row) * sourceBytesPerRow + originX),
          rowBytes
        )
      }
    }
    return true
  }

  /// 파일에 트랙을 섞어 쓰기 때문에 모든 트랙을 번갈아 옮기고, 모두 끝날 때까지 기다린다.
  /// 트랙은 더 넣을 수 없으면 콜백을 끝내 다음 트랙에 차례를 넘긴다. 콜백이 한 직렬 큐에서만 돌아 남은 트랙 목록에 잠금이 필요 없다.
  private static func copyAll(_ copies: [MovieTrackCopy], reader: AVAssetReader) async {
    // 읽기 객체도 `movieCroppingQueue`에서만 다룬다.
    nonisolated(unsafe) let reader = reader
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      nonisolated(unsafe) var unfinishedIndices = Set(copies.indices)

      // 실패한 트랙이 다른 트랙을 끝낼 수 있으므로 모든 콜백을 등록한 뒤에 복사가 시작되도록 같은 큐에서 등록한다.
      movieCroppingQueue.async {
        for (index, copy) in copies.enumerated() {
          copy.input.requestMediaDataWhenReady(on: movieCroppingQueue) {
            guard unfinishedIndices.contains(index) else { return }

            let finishedIndices: Set<Int>
            switch copyAvailableSamples(copy, reader: reader) {
            case .waiting:
              return
            case .finished:
              finishedIndices = [index]
            case .failed:
              // 한 트랙이라도 쓰지 못하면 결과 파일을 믿을 수 없으므로 전체를 멈춘다.
              reader.cancelReading()
              finishedIndices = unfinishedIndices
            }

            finishedIndices.forEach { copies[$0].input.markAsFinished() }
            unfinishedIndices.subtract(finishedIndices)
            if unfinishedIndices.isEmpty {
              continuation.resume()
            }
          }
        }
      }
    }
  }

  private static func copyAvailableSamples(_ copy: MovieTrackCopy, reader: AVAssetReader) -> MovieTrackCopyStatus {
    while copy.input.isReadyForMoreMediaData {
      guard let sampleBuffer = copy.output.copyNextSampleBuffer() else {
        return reader.status == .failed ? .failed : .finished
      }
      guard copy.append(sampleBuffer) else { return .failed }
    }
    return .waiting
  }
}
