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
  var quality: PreviewFrameQuality = .high

  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam",
    category: "PreviewCaptureService"
  )

  init() {
    (self.framePayloadStream, self.framePayloadContinuation) = AsyncStream.makeStream(of: VideoFramePayload.self)
  }

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
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoScalingModeKey: AVVideoScalingModeFit,
    ]

    bufferStream = previewCaptureDelegate?.bufferStream

    previewOutput.setSampleBufferDelegate(previewCaptureDelegate, queue: previewCaptureQueue)

    logger.info("started to capture preveiw stream")
    logger.info("video settings: \(self.previewOutput.videoSettings ?? [:])")

    // MARK: - render frame
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
}

extension PreviewCaptureService {
  private func setupFrameProcessing() async {
    let ciContext = CIContext()
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    if let bufferStream = self.bufferStream {
      for await buffer in bufferStream {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
          self.logger.warning("video buffer에 imageBuffer가 없음")
          continue  // 다음 프레임으로 넘어갑니다.
        }

        // ----- 1. 현재 화질 가져오기 -----
        let quality = self.quality
        let scaleFactor = quality.scale
        let jpegQuality = quality.jpegQuality

        // ----- 2. 원본 CIImage -----
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let originalSize = ciImage.extent.size

        // ----- 3. 다운스케일 -----
        if scaleFactor < 1.0 {
          let filter = CIFilter(name: "CILanczosScaleTransform")!
          filter.setValue(ciImage, forKey: kCIInputImageKey)
          filter.setValue(scaleFactor, forKey: kCIInputScaleKey)
          filter.setValue(1.0, forKey: kCIInputAspectRatioKey)
          guard let output = filter.outputImage else {
            self.logger.warning("CILanczosScaleTransform 실패")
            continue
          }
          ciImage = output
        }

        let scaledSize = ciImage.extent.size

        // ----- 4. JPEG 변환 -----
        guard
          let imageData = ciContext.jpegRepresentation(
            of: ciImage,
            colorSpace: colorSpace,
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: jpegQuality]
          )
        else {
          self.logger.warning("CIImage -> JPEG 변환 실패")
          continue
        }

        // ----- 5. 프레임 방출 -----
        framePayloadContinuation.yield(
          VideoFramePayload(
            frameData: imageData,
            originalSize: originalSize,
            scaledSize: scaledSize,
            quality: quality,
            timestamp: Date()
          )
        )
      }
    }
  }
}

// MARK: - Delegate
final class PreviewCaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

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
