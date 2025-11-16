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

  /// 비디오 인코더
  var videoEncoder: VideoEncoder?
  var encoderStreamTask: Task<Void, Never>?
  var videoEncoderAnnexBAdaptor: VideoEncoderAnnexBAdaptor?

  /// 프레임 처리를 위한 CIContext
  let ciContext = CIContext(options: nil)

  private let logger = QueenLogger(category: "PreviewCaptureService")

  init() {
    (self.framePayloadStream, self.framePayloadContinuation) = AsyncStream.makeStream(of: VideoFramePayload.self)

    logger.debug("PreviewCaptureService init")
  }

  deinit {
    logger.debug("PreviewCaptureService deinit")
  }
}

// MARK: - 캡쳐 시작 / 중지
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
    setupEncoder()

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

// MARK: - 인코더 설정
extension PreviewCaptureService {
  func setupEncoder() {
    let videoEncoder = VideoEncoder(config: .queenCamCustomConfig)
    self.videoEncoder = videoEncoder

    let videoEncoderAnnexBAdaptor = VideoEncoderAnnexBAdaptor(videoEncoder: videoEncoder)
    self.videoEncoderAnnexBAdaptor = videoEncoderAnnexBAdaptor

    encoderStreamTask = Task { [weak self] in
      guard let self else { return }

      for await payload in videoEncoderAnnexBAdaptor.annexBData {
        let framePayloadContinuation = await self.framePayloadContinuation
        framePayloadContinuation.yield(
          VideoFramePayload(
            hevcData: payload.annexBData,
            firstFrameTimeStamp: payload.firstFrameTimestamp,
            presetationTimeStamp: payload.presentationTimestamp,
            quality: await self.quality
          )
        )
      }
    }
  }

  private func setupFrameProcessing() async {
    if let bufferStream = self.bufferStream {
      for await buffer in bufferStream {
        var resizedBuffer: CMSampleBuffer

        // MARK: Quality에 따라 해상도 조정
        let scale = quality.scale

        if scale == 1.0 {
          resizedBuffer = buffer
        } else {
          // 원본 픽셀 버퍼 가져오기
          guard let originalPixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            self.logger.warning("Failed to get CVPixelBuffer from CMSampleBuffer.")
            continue  // 이 프레임 건너뛰기
          }

          // 픽셀 버퍼 리사이징
          guard let newPixelBuffer = resizePixelBuffer(originalPixelBuffer, scale: scale) else {
            self.logger.warning("Failed to resize CVPixelBuffer.")
            continue
          }

          // 리사이징된 픽셀 버퍼와 원본 시간 정보 조합
          guard let newSampleBuffer = createSampleBuffer(from: newPixelBuffer, withTimingOf: buffer) else {
            self.logger.warning("Failed to create new CMSampleBuffer.")
            continue
          }

          resizedBuffer = newSampleBuffer
        }

        videoEncoder?.encode(resizedBuffer)
      }
    }
  }
}
