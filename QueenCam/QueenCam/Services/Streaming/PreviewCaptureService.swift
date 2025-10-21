//
//  PreviewCaptureService.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import AVFoundation
import CoreImage
import Foundation
import OSLog
import Transcoding

final actor PreviewCaptureService {
  private(set) var isCapturing: Bool = false

  /// The capture output type for this service.
  let output = AVCaptureVideoDataOutput()

  // An internal alias for the output.
  private var previewOutput: AVCaptureVideoDataOutput { output }

  private var previewCaptureDelegate: PreviewCaptureDelegate?

  private let previewCaptureQueue = DispatchQueue(label: "com.queendom.QueenCam.previewCaptureQueue")

  /// Buffer Async Steam
  private(set) var bufferStream: AsyncStream<CMSampleBuffer>?

  /// Out frames stream
  var framePayloadStream: AsyncStream<VideoFramePayload>
  var framePayloadContinuation: AsyncStream<VideoFramePayload>.Continuation

  /// 렌더링 품질
  var quality: PreviewFrameQuality = .medium

  /// Goal FPS
  private let transferingFPS: Double = 30.0  // 목표 FPS를 30으로 설정
  private var lastPresentationTime: TimeInterval = 0.0

  /// 비디오 인코더
  let videoEncoder = VideoEncoder(config: .ultraLowLatency)
  var encoderStreamTask: Task<Void, Never>?
  lazy var videoEncoderAnnexBAdaptor = VideoEncoderAnnexBAdaptor(
      videoEncoder: videoEncoder
  )

  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam",
    category: "PreviewCaptureService"
  )

  init() {
    (self.framePayloadStream, self.framePayloadContinuation) = AsyncStream.makeStream(of: VideoFramePayload.self)
  }
}

extension PreviewCaptureService {
  // MARK: - Start to capture

  /// The app calls this method when the user taps the photo capture button.
  func startCapturePreviewStream() {
    guard !isCapturing else {
      logger.warning("이미 녹화가 진행중입니다.")
      return
    }

    logger.info("capture preview stream starting...")
    isCapturing = true

    previewCaptureDelegate = PreviewCaptureDelegate()

    // Capture
    previewOutput.videoSettings = [
      AVVideoCodecKey: AVVideoCodecType.h264
    ]

    bufferStream = previewCaptureDelegate?.bufferStream

    previewOutput.setSampleBufferDelegate(previewCaptureDelegate, queue: previewCaptureQueue)

    logger.info("started to capture preveiw stream")
    logger.info("video settings: \(self.previewOutput.videoSettings ?? [:])")

    // MARK: setup HEVC encoder
    if let width = self.previewOutput.videoSettings[kCVPixelBufferWidthKey as String] as? Int,
      let height = self.previewOutput.videoSettings[kCVPixelBufferHeightKey as String] as? Int
    {
      setupEncoder()
    } else {
      logger.error("Cannot read width and height from videoSettings")
    }

    // MARK: set to render frame

    Task {
      await setupFrameProcessing()
    }
  }

  func stopCapturePreviewStream() {
    bufferStream = nil

    isCapturing = false

    previewCaptureDelegate = nil

    previewOutput.setSampleBufferDelegate(nil, queue: previewCaptureQueue)

    logger.info("stopped to capture preveiw stream")
  }

  private func mutateQuality(_ quality: PreviewFrameQuality) {
    self.quality = quality
  }

  nonisolated func setQuality(to quality: PreviewFrameQuality) async {
    await mutateQuality(quality)
  }
}

extension PreviewCaptureService {
  func setupEncoder() {
    encoderStreamTask = Task { [weak self] in
      guard let self else { return }
      
      for await data in await videoEncoderAnnexBAdaptor.annexBData {
        let framePayloadContinuation = await self.framePayloadContinuation
          framePayloadContinuation.yield(
            VideoFramePayload(
              data: data,
              originalSize: .zero,
              scaledSize: .zero,
              quality: .high,
              timestamp: Date()
            )
          )
      }
    }
  }

  private func setupFrameProcessing() async {
    if let bufferStream = self.bufferStream {
      for await buffer in bufferStream {
        videoEncoder.encode(buffer)
      }
    }
  }
}

// MARK: - Delegate
nonisolated final class PreviewCaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

  let bufferStream: AsyncStream<CMSampleBuffer>
  private let bufferStreamContinuation: AsyncStream<CMSampleBuffer>.Continuation

  override init() {
    let (bufferStream, bufferStreamContinuation) = AsyncStream.makeStream(of: CMSampleBuffer.self)

    self.bufferStream = bufferStream
    self.bufferStreamContinuation = bufferStreamContinuation

    super.init()
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    bufferStreamContinuation.yield(sampleBuffer)
  }
}
