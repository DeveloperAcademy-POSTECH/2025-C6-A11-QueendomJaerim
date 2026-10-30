//
//  LivePhotoMovieCroppingTests.swift
//  QueenCamTests
//
//  Created by seungchan on 10/28/26.
//

import AVFoundation
import CoreMedia
import CoreVideo
import Foundation
import Testing

@testable import QueenCam

@Suite("PhotoAspectRatioCroppingService Live Photo 영상 Tests")
struct LivePhotoMovieCroppingTests {
  private let service = PhotoAspectRatioCroppingService()

  @Test("4:3 영상을 4:3으로 자르면 원본 파일을 그대로 돌려준다")
  func returnsOriginalURLFor4x3() async throws {
    let source = try await LivePhotoMovieFixture.make()

    #expect(await service.crop(livePhotoMovieURL: source.url, to: .ratio4x3) == source.url)
  }

  @Test("16:9로 자르면 화면 크기만 바뀌고 방향·길이는 그대로다")
  func cropsVideoTo16x9() async throws {
    let source = try await LivePhotoMovieFixture.make()

    let croppedURL = try #require(await service.crop(livePhotoMovieURL: source.url, to: .ratio16x9))
    let cropped = try await LivePhotoMovieFixture.Info.load(from: croppedURL)

    #expect(croppedURL != source.url)
    #expect(cropped.videoSize == CGSize(width: 640, height: 360))
    #expect(cropped.transform == source.info.transform)
    #expect(cropped.duration == source.info.duration)
  }

  @Test("1:1로 자르면 정사각형이 된다")
  func cropsVideoTo1x1() async throws {
    let source = try await LivePhotoMovieFixture.make()

    let croppedURL = try #require(await service.crop(livePhotoMovieURL: source.url, to: .ratio1x1))

    #expect(try await LivePhotoMovieFixture.Info.load(from: croppedURL).videoSize == CGSize(width: 480, height: 480))
  }

  @Test("실제 그림이 표시 영역보다 큰 영상은 표시 영역 안에서 가운데를 자른다", arguments: [PhotoAspectRatio.ratio16x9, .ratio1x1])
  func cropsInsideCleanAperture(ratio: PhotoAspectRatio) async throws {
    let source = try await LivePhotoMovieFixture.make(hasCleanAperture: true)

    let croppedURL = try #require(await service.crop(livePhotoMovieURL: source.url, to: ratio))

    #expect(source.info.videoSize == CGSize(width: 560, height: 420))
    #expect(try await LivePhotoMovieFixture.darkestCornerLuma(of: croppedURL) > LivePhotoMovieFixture.brightLumaThreshold)
  }

  @Test("소리·대표 사진 시점 정보·짝 식별자를 원본 그대로 옮긴다")
  func keepsLivePhotoInformation() async throws {
    let source = try await LivePhotoMovieFixture.make()

    let croppedURL = try #require(await service.crop(livePhotoMovieURL: source.url, to: .ratio16x9))
    let cropped = try await LivePhotoMovieFixture.Info.load(from: croppedURL)

    #expect(cropped.audioTrackCount == 1)
    #expect(cropped.audioDuration == source.info.audioDuration)
    #expect(cropped.metadataTrackCount == 1)
    #expect(cropped.contentIdentifier == source.info.contentIdentifier)
    #expect(cropped.contentIdentifier != nil)
  }

  @Test("영상이 아닌 파일은 자르지 못하고 nil을 돌려준다")
  func returnsNilForInvalidFile() async throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("mov")
    try Data("not a movie".utf8).write(to: url)

    #expect(await service.crop(livePhotoMovieURL: url, to: .ratio16x9) == nil)
  }
}

/// 라이브 포토 영상과 같은 구성의 짧은 테스트 영상을 만든다.
/// 640×480 화면(90도 회전 정보), 무음 소리, 대표 사진 시점 메타데이터 트랙, 짝 식별자를 담는다.
enum LivePhotoMovieFixture {
  static let width = 640
  static let height = 480
  static let frameCount = 10
  static let frameRate: Int32 = 30
  static let sampleRate = 44_100.0
  static let brightLumaThreshold: UInt8 = 200

  /// 카메라 영상처럼 실제 그림은 640×480이고 가운데 560×420만 표시하는 영역. 표시 영역 밖은 검게 칠한다.
  private static let cleanAperture = CGRect(x: 40, y: 30, width: 560, height: 420)

  struct Source {
    let url: URL
    let info: Info
  }

  struct Info: Equatable {
    let videoSize: CGSize
    let transform: CGAffineTransform
    let duration: CMTime
    let audioTrackCount: Int
    let audioDuration: CMTime?
    let metadataTrackCount: Int
    let contentIdentifier: String?

    static func load(from url: URL) async throws -> Info {
      let asset = AVURLAsset(url: url)
      let videoTrack = try #require(try await asset.loadTracks(withMediaType: .video).first)
      let audioTracks = try await asset.loadTracks(withMediaType: .audio)
      let metadataTracks = try await asset.loadTracks(withMediaType: .metadata)
      let metadata = try await asset.load(.metadata)
      let identifierItem = metadata.first { $0.identifier == .quickTimeMetadataContentIdentifier }

      return Info(
        videoSize: try await videoTrack.load(.naturalSize),
        transform: try await videoTrack.load(.preferredTransform),
        duration: try await videoTrack.load(.timeRange).duration,
        audioTrackCount: audioTracks.count,
        audioDuration: try await audioTracks.first?.load(.timeRange).duration,
        metadataTrackCount: metadataTracks.count,
        contentIdentifier: try await identifierItem?.load(.stringValue)
      )
    }
  }

  static func make(hasCleanAperture: Bool = false) async throws -> Source {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("mov")
    let writer = try AVAssetWriter(outputURL: url, fileType: .mov)

    let identifier = AVMutableMetadataItem()
    identifier.identifier = .quickTimeMetadataContentIdentifier
    identifier.value = UUID().uuidString as NSString
    identifier.dataType = kCMMetadataBaseDataType_UTF8 as String
    writer.metadata = [identifier]

    let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings(hasCleanAperture: hasCleanAperture))
    videoInput.transform = CGAffineTransform(rotationAngle: .pi / 2)
    let pixelAdaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: videoInput,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height
      ]
    )

    let audioInput = AVAssetWriterInput(
      mediaType: .audio,
      outputSettings: [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVNumberOfChannelsKey: 1,
        AVSampleRateKey: sampleRate
      ]
    )

    let metadataInput = AVAssetWriterInput(
      mediaType: .metadata,
      outputSettings: nil,
      sourceFormatHint: try makeStillImageTimeFormatDescription()
    )
    let metadataAdaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: metadataInput)

    for input in [videoInput, audioInput, metadataInput] {
      try #require(writer.canAdd(input))
      writer.add(input)
    }

    #expect(writer.startWriting())
    writer.startSession(atSourceTime: .zero)

    for index in 0..<frameCount {
      let time = CMTime(value: CMTimeValue(index), timescale: frameRate)
      while !videoInput.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(5)) }
      #expect(pixelAdaptor.append(try makePixelBuffer(hasCleanAperture: hasCleanAperture), withPresentationTime: time))
    }
    videoInput.markAsFinished()

    let movieDuration = CMTime(value: CMTimeValue(frameCount), timescale: frameRate)
    while !audioInput.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(5)) }
    #expect(audioInput.append(try makeSilentAudio(duration: movieDuration)))
    audioInput.markAsFinished()

    while !metadataInput.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(5)) }
    #expect(metadataAdaptor.append(makeStillImageTimeGroup()))
    metadataInput.markAsFinished()

    writer.endSession(atSourceTime: movieDuration)
    await writer.finishWriting()
    try #require(writer.status == .completed)

    return Source(url: url, info: try await Info.load(from: url))
  }

  private static func videoSettings(hasCleanAperture: Bool) -> [String: Any] {
    var settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height]
    if hasCleanAperture {
      settings[AVVideoCleanApertureKey] = [
        AVVideoCleanApertureWidthKey: Int(cleanAperture.width),
        AVVideoCleanApertureHeightKey: Int(cleanAperture.height),
        AVVideoCleanApertureHorizontalOffsetKey: 0,
        AVVideoCleanApertureVerticalOffsetKey: 0
      ]
    }
    return settings
  }

  private static func makeStillImageTimeGroup() -> AVTimedMetadataGroup {
    let stillImageTime = AVMutableMetadataItem()
    stillImageTime.key = "com.apple.quicktime.still-image-time" as NSString
    stillImageTime.keySpace = .quickTimeMetadata
    stillImageTime.value = 0 as NSNumber
    stillImageTime.dataType = kCMMetadataBaseDataType_SInt8 as String

    let timeRange = CMTimeRange(
      start: CMTime(value: 3, timescale: frameRate),
      duration: CMTime(value: 1, timescale: frameRate)
    )
    return AVTimedMetadataGroup(items: [stillImageTime], timeRange: timeRange)
  }

  private static func makeStillImageTimeFormatDescription() throws -> CMFormatDescription {
    let specification: [String: Any] = [
      kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String:
        "mdta/com.apple.quicktime.still-image-time",
      kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String:
        kCMMetadataBaseDataType_SInt8 as String
    ]
    var description: CMFormatDescription?
    let status = CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
      allocator: kCFAllocatorDefault,
      metadataType: kCMMetadataFormatType_Boxed,
      metadataSpecifications: [specification] as CFArray,
      formatDescriptionOut: &description
    )
    try #require(status == noErr)
    return try #require(description)
  }

  /// 영상 첫 장면의 네 모서리 밝기 중 가장 어두운 값. 표시 영역 밖의 검은 부분이 섞여 있으면 낮게 나온다.
  static func darkestCornerLuma(of url: URL) async throws -> UInt8 {
    let asset = AVURLAsset(url: url)
    let track = try #require(try await asset.loadTracks(withMediaType: .video).first)
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(
      track: track,
      outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
    )
    reader.add(output)
    #expect(reader.startReading())
    let sampleBuffer = try #require(output.copyNextSampleBuffer())
    let buffer = try #require(CMSampleBufferGetImageBuffer(sampleBuffer))
    reader.cancelReading()

    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

    let baseAddress = try #require(CVPixelBufferGetBaseAddressOfPlane(buffer, 0))
    let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
    let lastColumn = CVPixelBufferGetWidthOfPlane(buffer, 0) - 8
    let lastRow = CVPixelBufferGetHeightOfPlane(buffer, 0) - 8
    let corners = [(8, 8), (lastColumn, 8), (8, lastRow), (lastColumn, lastRow)].map { column, row in
      baseAddress.load(fromByteOffset: row * bytesPerRow + column, as: UInt8.self)
    }
    return try #require(corners.min())
  }

  private static func makePixelBuffer(hasCleanAperture: Bool) throws -> CVPixelBuffer {
    var pixelBuffer: CVPixelBuffer?
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
    let buffer = try #require(pixelBuffer)
    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

    let baseAddress = try #require(CVPixelBufferGetBaseAddress(buffer))
    guard hasCleanAperture else {
      memset(baseAddress, 0x80, CVPixelBufferGetDataSize(buffer))
      return buffer
    }

    let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
    memset(baseAddress, 0x00, CVPixelBufferGetDataSize(buffer))
    for row in Int(cleanAperture.minY)..<Int(cleanAperture.maxY) {
      memset(
        baseAddress.advanced(by: row * bytesPerRow + Int(cleanAperture.minX) * 4),
        0xFF,
        Int(cleanAperture.width) * 4
      )
    }
    return buffer
  }

  private static func makeSilentAudio(duration: CMTime) throws -> CMSampleBuffer {
    let frameCount = Int(duration.seconds * sampleRate)
    var streamDescription = AudioStreamBasicDescription(
      mSampleRate: sampleRate,
      mFormatID: kAudioFormatLinearPCM,
      mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
      mBytesPerPacket: 2,
      mFramesPerPacket: 1,
      mBytesPerFrame: 2,
      mChannelsPerFrame: 1,
      mBitsPerChannel: 16,
      mReserved: 0
    )
    var formatDescription: CMAudioFormatDescription?
    CMAudioFormatDescriptionCreate(
      allocator: kCFAllocatorDefault,
      asbd: &streamDescription,
      layoutSize: 0,
      layout: nil,
      magicCookieSize: 0,
      magicCookie: nil,
      extensions: nil,
      formatDescriptionOut: &formatDescription
    )

    let byteCount = frameCount * 2
    var blockBuffer: CMBlockBuffer?
    CMBlockBufferCreateWithMemoryBlock(
      allocator: kCFAllocatorDefault,
      memoryBlock: nil,
      blockLength: byteCount,
      blockAllocator: kCFAllocatorDefault,
      customBlockSource: nil,
      offsetToData: 0,
      dataLength: byteCount,
      flags: kCMBlockBufferAssureMemoryNowFlag,
      blockBufferOut: &blockBuffer
    )
    let block = try #require(blockBuffer)
    CMBlockBufferFillDataBytes(with: 0, blockBuffer: block, offsetIntoDestination: 0, dataLength: byteCount)

    var sampleBuffer: CMSampleBuffer?
    CMAudioSampleBufferCreateReadyWithPacketDescriptions(
      allocator: kCFAllocatorDefault,
      dataBuffer: block,
      formatDescription: try #require(formatDescription),
      sampleCount: frameCount,
      presentationTimeStamp: .zero,
      packetDescriptions: nil,
      sampleBufferOut: &sampleBuffer
    )
    return try #require(sampleBuffer)
  }
}
