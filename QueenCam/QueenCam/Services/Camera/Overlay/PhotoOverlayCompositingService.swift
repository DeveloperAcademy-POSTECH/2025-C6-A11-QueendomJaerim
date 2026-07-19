//
//  PhotoOverlayCompositingService.swift
//  QueenCam
//
//  Created by 임영택 on 6/21/26.
//

import AVFoundation
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

final class PhotoOverlayCompositingService: PhotoOverlayCompositingServiceProtocol {
  private static let livePhotoMakerAppleAssetIdentifierKey = "17"
  private static let quickTimeContentIdentifierKey = "com.apple.quicktime.content.identifier"
  private static let jpegCompressionQuality = 0.95

  // 호출부는 프로토콜을 통해 테스트 대역으로 교체할 수 있도록 인스턴스 메서드만 바라본다.
  // 실제 합성 과정 중 인스턴스 상태가 필요 없는 metadata/JPEG 변환 로직은 static helper로 분리한다.
  func composite(photoOutput: PhotoOuput, strokes: [DrawableStroke]) -> PhotoOuput {
    guard !strokes.isEmpty else { return photoOutput }

    switch photoOutput {
    case .basicPhoto(_, let imageData):
      guard
        let image = makeCompositeImage(from: imageData, strokes: strokes),
        let compositeData = Self.makeJPEGData(from: image, originalImageData: imageData)
      else { return photoOutput }

      return .basicPhoto(thumbnail: image, imageData: compositeData)
    case .livePhoto(_, let imageData, let videoData):
      // Live Photo는 still image와 paired video가 같은 content identifier를 가져야 Photos에서 하나의 자산으로 묶인다.
      // 합성 과정에서 still image를 새 JPEG로 다시 쓰면 MakerApple metadata가 사라질 수 있으므로,
      // 원본 still 또는 paired video에서 identifier를 읽어 새 JPEG metadata에 다시 심는다.
      let assetIdentifier = Self.livePhotoAssetIdentifier(from: imageData)
        ?? Self.livePhotoAssetIdentifier(fromVideoData: videoData)

      guard
        let assetIdentifier,
        let image = makeCompositeImage(from: imageData, strokes: strokes),
        let compositeData = Self.makeJPEGData(
          from: image,
          originalImageData: imageData,
          livePhotoAssetIdentifier: assetIdentifier
        )
      else { return photoOutput }

      return .livePhoto(thumbnail: image, imageData: compositeData, videoData: videoData)
    }
  }
}

private extension PhotoOverlayCompositingService {
  func makeCompositeImage(from imageData: Data, strokes: [DrawableStroke]) -> UIImage? {
    guard let image = UIImage(data: imageData) else { return nil }

    let format = UIGraphicsImageRendererFormat()
    format.scale = image.scale
    format.opaque = true

    let imageSize = image.size
    let imageRect = CGRect(origin: .zero, size: imageSize)
    let overlayRect = StrokeOverlayGeometry.aspectFitRect(in: imageRect)
    let lineScale = StrokeOverlayGeometry.lineScale(for: overlayRect)

    return UIGraphicsImageRenderer(size: imageSize, format: format).image { rendererContext in
      image.draw(in: imageRect)

      let context = rendererContext.cgContext
      for stroke in strokes {
        drawNormalStroke(
          points: stroke.points,
          author: stroke.author,
          in: context,
          overlayRect: overlayRect,
          lineScale: lineScale
        )
      }
    }
  }

  func drawNormalStroke(
    points: [CGPoint],
    author: Role,
    in context: CGContext,
    overlayRect: CGRect,
    lineScale: CGFloat
  ) {
    let path = StrokeOverlayGeometry.bezierPath(from: points, in: overlayRect)
    let style = StrokeRenderStyleResolver.normalStrokeStyle(for: author, lineScale: lineScale)

    stroke(path, in: context, color: style.backgroundUIColor, width: style.backgroundLineWidth)
    stroke(path, in: context, color: style.foregroundUIColor, width: style.foregroundLineWidth)
  }

  func stroke(_ path: UIBezierPath, in context: CGContext, color: UIColor, width: CGFloat) {
    context.saveGState()
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
    context.restoreGState()
  }
}

private extension PhotoOverlayCompositingService {
  // 이미지 metadata와 JPEG 재작성은 인스턴스 상태와 무관하다.
  // 프로토콜 진입점은 유지하되, 순수 변환에 가까운 세부 로직은 static으로 두어 의존성을 좁힌다.
  static func makeJPEGData(
    from image: UIImage,
    originalImageData: Data,
    livePhotoAssetIdentifier: String? = nil
  ) -> Data? {
    guard let cgImage = image.cgImage else { return nil }

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
      return nil
    }

    // UIImage(data:)로 원본 JPEG를 읽으면 metadata의 orientation이 이미 반영된 상태로 메모리에 로드된다.
    // 이후 UIImage.draw(in:)로 합성 이미지를 만들면 회전이 적용된 픽셀 자체가 새 이미지에 기록된다.
    // 이 상태에서 원본 orientation metadata를 다시 복사하면 Photos가 저장된 픽셀을 한 번 더 회전해서 보여준다.
    // 따라서 촬영 시각/렌즈/기기 metadata는 보존하고, orientation metadata는 픽셀 기준인 .up으로 고정한다.
    var properties = imageProperties(from: originalImageData)
    properties[kCGImageDestinationLossyCompressionQuality as String] = jpegCompressionQuality
    normalizeOrientation(in: &properties)

    if let livePhotoAssetIdentifier {
      // Live Photo still image의 pairing identifier는 Apple MakerNote의 비공개 key "17"에 들어간다.
      // 새 JPEG를 만들면서 이 값이 빠지면 paired video와 같은 asset으로 묶이지 않아 저장 실패가 날 수 있다.
      // 그래서 원본 still/video에서 읽은 identifier를 새 still metadata에 다시 주입한다.
      var makerAppleDictionary = properties[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any] ?? [:]
      makerAppleDictionary[livePhotoMakerAppleAssetIdentifierKey] = livePhotoAssetIdentifier
      properties[kCGImagePropertyMakerAppleDictionary as String] = makerAppleDictionary
    }

    CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { return nil }

    return data as Data
  }

  static func normalizeOrientation(in properties: inout [String: Any]) {
    properties[kCGImagePropertyOrientation as String] = CGImagePropertyOrientation.up.rawValue

    if var tiffDictionary = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
      tiffDictionary[kCGImagePropertyTIFFOrientation as String] = CGImagePropertyOrientation.up.rawValue
      properties[kCGImagePropertyTIFFDictionary as String] = tiffDictionary
    }
  }

  static func imageProperties(from imageData: Data) -> [String: Any] {
    guard
      let source = CGImageSourceCreateWithData(imageData as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
    else { return [:] }

    return properties
  }

  static func livePhotoAssetIdentifier(from imageData: Data) -> String? {
    let makerAppleDictionary = imageProperties(from: imageData)[kCGImagePropertyMakerAppleDictionary as String]
      as? [String: Any]

    return makerAppleDictionary?[livePhotoMakerAppleAssetIdentifierKey] as? String
  }

  static func livePhotoAssetIdentifier(fromVideoData videoData: Data) -> String? {
    // Deferred/proxy 경로에서는 still image metadata에서 identifier를 못 읽을 수 있다.
    // AVURLAsset은 URL 기반으로 QuickTime metadata를 읽기 때문에 video Data를 임시 mov 파일로 쓴 뒤 즉시 삭제한다.
    let videoURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension(for: .quickTimeMovie)

    do {
      try videoData.write(to: videoURL)
      defer { try? FileManager.default.removeItem(at: videoURL) }

      let asset = AVURLAsset(url: videoURL)
      return asset.metadata(forFormat: .quickTimeMetadata)
        .first { item in
          item.identifier == .quickTimeMetadataContentIdentifier
            || item.key as? String == quickTimeContentIdentifierKey
        }?
        .stringValue
    } catch {
      return nil
    }
  }
}
