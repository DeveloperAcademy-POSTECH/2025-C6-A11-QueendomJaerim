import AVFoundation
import OSLog
import Photos
import UIKit

// MARK: - Crop Helpers
extension CameraDelegate {
  /// 원본 크기와 목표 비율을 비교해 중앙 크롭 영역(rect)을 계산한다.
  func centerCropRect(sourceSize: CGSize, targetRatio: CGFloat) -> CGRect {
    let sourceRatio = sourceSize.width / sourceSize.height

    if sourceRatio > targetRatio {
      let targetWidth = sourceSize.height * targetRatio
      let x = (sourceSize.width - targetWidth) / 2.0

      return CGRect(x: x, y: .zero, width: targetWidth, height: sourceSize.height).integral
    } else {
      let targetHeight = sourceSize.width / targetRatio
      let y = (sourceSize.height - targetHeight) / 2.0
      return CGRect(x: .zero, y: y, width: sourceSize.width, height: targetHeight).integral
    }
  }

  /// 세로/가로 소스 방향에 맞게 목표 비율을 정규화한다.
  func normalizedTargetRatio(selectedRatio: CGFloat, sourceSize: CGSize) -> CGFloat {
    // 1:1은 뒤집어도 동일하므로 그대로 사용한다.
    if selectedRatio == 1.0 {
      return 1.0
    }

    let sourceIsPortrait = sourceSize.height > sourceSize.width
    if sourceIsPortrait {
      // 세로 원본에서는 세로형 비율(<= 1)을 사용한다.
      return min(selectedRatio, 1.0 / selectedRatio)
    } else {
      // 가로 원본에서는 가로형 비율(>= 1)을 사용한다.
      return max(selectedRatio, 1.0 / selectedRatio)
    }
  }

  /// still 데이터에서 실제 픽셀 크기(CGImage 기준)를 읽는다.
  func sourceImageSize(from imageData: Data) -> CGSize? {
    guard
      let source = CGImageSourceCreateWithData(imageData as CFData, nil),
      let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      return nil
    }
    return CGSize(width: sourceImage.width, height: sourceImage.height)
  }

  /// Live Photo still에서 pair 메타데이터 손실을 줄이기 위해 metadata를 보존해서 크롭한다.
  func croppedImageDataPreservingMetadata(
    imageData: Data,
    targetRatio: CGFloat
  ) -> (thumbnail: UIImage, imageData: Data)? {
    guard
      let source = CGImageSourceCreateWithData(imageData as CFData, nil),
      let sourceType = CGImageSourceGetType(source),
      let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      return nil
    }

    let sourceSize = CGSize(width: sourceImage.width, height: sourceImage.height)
    let cropRect = centerCropRect(sourceSize: sourceSize, targetRatio: targetRatio)

    guard let croppedCGImage = sourceImage.cropping(to: cropRect) else {
      return nil
    }

    let metadata = (CGImageSourceCopyPropertiesAtIndex(source, .zero, nil) as? [CFString: Any]) ?? [:]
    let outputData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(outputData, sourceType, 1, nil) else {
      return nil
    }

    CGImageDestinationAddImage(destination, croppedCGImage, metadata as CFDictionary)
    guard CGImageDestinationFinalize(destination) else {
      return nil
    }

    let thumbnail = UIImage(cgImage: croppedCGImage)
    return (thumbnail: thumbnail, imageData: outputData as Data)
  }
}
