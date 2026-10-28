//
//  PhotoAspectRatioCroppingService.swift
//  QueenCam
//
//  Created by seungchan on 10/24/26.
//

import CoreGraphics
import CoreVideo
import Foundation
import ImageIO

nonisolated final class PhotoAspectRatioCroppingService: PhotoAspectRatioCroppingServiceProtocol {
  private static let lossyCompressionQuality = 0.95
  private static let logger = QueenLogger(category: "PhotoAspectRatioCroppingService")
  /// HDR 화면에서 밝은 부분을 표현하는 보조 이미지. 본 사진과 같은 영역으로 잘라 다시 붙인다.
  private static let gainMapTypes: [CFString] = [kCGImageAuxiliaryDataTypeHDRGainMap, kCGImageAuxiliaryDataTypeISOGainMap]

  // 카메라 사진은 픽셀을 눕혀 둔 채 방향 정보(EXIF)로 돌려 보여 준다.
  // 가운데 자르기는 회전·반전과 상관없이 같은 영역이므로 픽셀을 돌리지 않고 자르고, 방향 정보는 그대로 둔다.
  func crop(imageData: Data, to ratio: PhotoAspectRatio) -> Data? {
    guard
      let source = CGImageSourceCreateWithData(imageData as CFData, nil),
      let type = CGImageSourceGetType(source),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
      let cropRect = PhotoAspectRatioGeometry.centerCropRect(
        imageSize: CGSize(width: image.width, height: image.height),
        ratio: ratio
      )
    else { return nil }

    guard cropRect != CGRect(x: 0, y: 0, width: image.width, height: image.height) else { return imageData }

    guard let croppedImage = image.cropping(to: cropRect) else { return nil }

    var properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]
    properties[kCGImageDestinationLossyCompressionQuality as String] = Self.lossyCompressionQuality
    Self.updatePixelDimensions(in: &properties, width: croppedImage.width, height: croppedImage.height)

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, type, 1, nil) else { return nil }
    CGImageDestinationAddImage(destination, croppedImage, properties as CFDictionary)
    Self.addCroppedGainMaps(
      from: source,
      to: destination,
      imageSize: CGSize(width: image.width, height: image.height),
      cropRect: cropRect
    )
    guard CGImageDestinationFinalize(destination) else { return nil }

    return data as Data
  }
}

private extension PhotoAspectRatioCroppingService {
  static func updatePixelDimensions(in properties: inout [String: Any], width: Int, height: Int) {
    properties[kCGImagePropertyPixelWidth as String] = width
    properties[kCGImagePropertyPixelHeight as String] = height

    if var exifDictionary = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
      exifDictionary[kCGImagePropertyExifPixelXDimension as String] = width
      exifDictionary[kCGImagePropertyExifPixelYDimension as String] = height
      properties[kCGImagePropertyExifDictionary as String] = exifDictionary
    }
  }

  static func addCroppedGainMaps(
    from source: CGImageSource,
    to destination: CGImageDestination,
    imageSize: CGSize,
    cropRect: CGRect
  ) {
    for type in gainMapTypes {
      guard let info = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, type) as? [String: Any] else { continue }

      guard let croppedInfo = croppedAuxiliaryDataInfo(info, imageSize: imageSize, cropRect: cropRect) else {
        let description = info[kCGImageAuxiliaryDataInfoDataDescription as String].map { "\($0)" } ?? "none"
        logger.warning("Failed to crop auxiliary data \(type). It is not kept in the cropped photo. description=\(description)")
        continue
      }
      CGImageDestinationAddAuxiliaryDataInfo(destination, type, croppedInfo as CFDictionary)
    }
  }

  /// gain map은 본 사진보다 작은 비트맵이다. 본 사진의 크롭 영역을 같은 비율로 줄여 그 줄만 복사한다.
  static func croppedAuxiliaryDataInfo(_ info: [String: Any], imageSize: CGSize, cropRect: CGRect) -> [String: Any]? {
    guard
      let data = info[kCGImageAuxiliaryDataInfoData as String] as? Data,
      var description = info[kCGImageAuxiliaryDataInfoDataDescription as String] as? [String: Any],
      let width = description["Width"] as? Int,
      let height = description["Height"] as? Int,
      let bytesPerRow = description["BytesPerRow"] as? Int,
      let pixelFormat = description["PixelFormat"] as? Int,
      let bytesPerPixel = bytesPerPixel(of: OSType(pixelFormat)),
      width > 0, height > 0, bytesPerRow >= width * bytesPerPixel, data.count >= bytesPerRow * height
    else { return nil }

    let scaleX = CGFloat(width) / imageSize.width
    let scaleY = CGFloat(height) / imageSize.height
    let minX = min(Int((cropRect.minX * scaleX).rounded(.down)), width - 1)
    let minY = min(Int((cropRect.minY * scaleY).rounded(.down)), height - 1)
    let croppedWidth = min(max(Int((cropRect.width * scaleX).rounded()), 1), width - minX)
    let croppedHeight = min(max(Int((cropRect.height * scaleY).rounded()), 1), height - minY)

    let croppedBytesPerRow = croppedWidth * bytesPerPixel
    var croppedData = Data(capacity: croppedBytesPerRow * croppedHeight)
    for row in minY..<(minY + croppedHeight) {
      let start = row * bytesPerRow + minX * bytesPerPixel
      croppedData.append(data[start..<(start + croppedBytesPerRow)])
    }

    description["Width"] = croppedWidth
    description["Height"] = croppedHeight
    description["BytesPerRow"] = croppedBytesPerRow

    var croppedInfo = info
    croppedInfo[kCGImageAuxiliaryDataInfoData as String] = croppedData
    croppedInfo[kCGImageAuxiliaryDataInfoDataDescription as String] = description
    return croppedInfo
  }

  static func bytesPerPixel(of pixelFormat: OSType) -> Int? {
    switch pixelFormat {
    case kCVPixelFormatType_OneComponent8:
      return 1
    case kCVPixelFormatType_OneComponent16Half, kCVPixelFormatType_OneComponent16:
      return 2
    case kCVPixelFormatType_OneComponent32Float, kCVPixelFormatType_32BGRA, kCVPixelFormatType_32ARGB, kCVPixelFormatType_32RGBA:
      return 4
    case kCVPixelFormatType_24RGB:
      return 3
    case kCVPixelFormatType_64RGBAHalf:
      return 8
    default:
      return nil
    }
  }
}
