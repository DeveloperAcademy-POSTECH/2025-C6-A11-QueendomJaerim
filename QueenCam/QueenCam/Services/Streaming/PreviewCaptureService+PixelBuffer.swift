//
//  PreviewCaptureService+PixelBuffer.swift
//  QueenCam
//
//  Created by 임영택 on 10/22/25.
//

import AVFoundation
import CoreImage
import OSLog

// MARK: - 픽셀 버퍼 처리 로직
extension PreviewCaptureService {
  private var logger: Logger {
    Logger(
      subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam",
      category: "PreviewCaptureService+PixelBuffer"
    )
  }
  
  /**
   CoreImage를 사용해 CVPixelBuffer를 리사이징한다.
   */
  func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer, scale: CGFloat) -> CVPixelBuffer? {
    let originalWidth = CVPixelBufferGetWidth(pixelBuffer)
    let originalHeight = CVPixelBufferGetHeight(pixelBuffer)

    let newWidth = Int(ceil(CGFloat(originalWidth) * scale))
    let newHeight = Int(ceil(CGFloat(originalHeight) * scale))

    // 새 크기에 맞는 CVPixelBuffer를 생성
    var newPixelBuffer: CVPixelBuffer?
    let attributes =
      [
        kCVPixelBufferIOSurfacePropertiesKey: [:]
      ] as CFDictionary

    let status = CVPixelBufferCreate(
      nil,
      newWidth,
      newHeight,
      CVPixelBufferGetPixelFormatType(pixelBuffer), // 원본과 동일한 픽셀 포맷 사용
      attributes,
      &newPixelBuffer
    )

    guard status == kCVReturnSuccess, let unwrappedNewPixelBuffer = newPixelBuffer else {
      self.logger.error("Failed to create new CVPixelBuffer for resizing.")
      return nil
    }

    // CoreImage로 스케일링 수행
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let scaleX = CGFloat(newWidth) / CGFloat(originalWidth)
    let scaleY = CGFloat(newHeight) / CGFloat(originalHeight)
    let scaledImage = ciImage.transformed(by: .init(scaleX: scaleX, y: scaleY))

    // 스케일링된 CIImage를 새로 만든 CVPixelBuffer에 렌더링
    ciContext.render(scaledImage, to: unwrappedNewPixelBuffer)

    return unwrappedNewPixelBuffer
  }

  /**
   새 CVPixelBuffer와 원본 CMSampleBuffer의 시간 정보를 조합해 새 CMSampleBuffer를 생성한다.
   */
  func createSampleBuffer(
    from pixelBuffer: CVPixelBuffer,
    withTimingOf originalSampleBuffer: CMSampleBuffer
  ) -> CMSampleBuffer? {
    var newSampleBuffer: CMSampleBuffer?
    var timingInfo: CMSampleTimingInfo = .invalid

    // 1. 원본 버퍼에서 시간 정보(PTS, Duration)를 가져옵니다.
    guard CMSampleBufferGetSampleTimingInfo(originalSampleBuffer, at: 0, timingInfoOut: &timingInfo) == noErr else {
      self.logger.error("Failed to get timing info from original sample buffer.")
      return nil
    }

    // CMVideoFormatDescription 생성
    var formatDescription: CMVideoFormatDescription?
    guard
      CMVideoFormatDescriptionCreateForImageBuffer(
        allocator: kCFAllocatorDefault,
        imageBuffer: pixelBuffer,
        formatDescriptionOut: &formatDescription
      ) == noErr
    else {
      self.logger.error("Failed to create CMVideoFormatDescription.")
      return nil
    }

    // 새 샘플 버퍼 생성
    guard
      CMSampleBufferCreateReadyWithImageBuffer(
        allocator: kCFAllocatorDefault,
        imageBuffer: pixelBuffer,
        formatDescription: formatDescription!,
        sampleTiming: &timingInfo,
        sampleBufferOut: &newSampleBuffer
      ) == noErr
    else {
      self.logger.error("Failed to create new CMSampleBuffer.")
      return nil
    }

    return newSampleBuffer
  }
}
