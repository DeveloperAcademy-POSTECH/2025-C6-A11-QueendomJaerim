//
//  PenPhotoOverlayComposer.swift
//  QueenCam
//
//  Created by 임영택 on 6/14/26.
//

import AVFoundation
import CoreImage
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

final class PenPhotoOverlayComposer {
  private struct OverlayStroke {
    let id: UUID
    let points: [CGPoint]
    let isMagicPen: Bool
    let author: Role
  }

  private let lock = NSLock()
  private let ciContext = CIContext()
  private var visibleStrokes: [OverlayStroke] = []

  func replaceVisibleStrokes(_ strokes: [Stroke]) {
    let overlayStrokes = strokes
      .filter { $0.points.count > 1 }
      .map {
        OverlayStroke(
          id: $0.id,
          points: $0.points,
          isMagicPen: $0.isMagicPen,
          author: $0.author
        )
      }

    lock.lock()
    visibleStrokes = overlayStrokes
    lock.unlock()
  }

  func clear() {
    lock.lock()
    visibleStrokes.removeAll()
    lock.unlock()
  }

  func makeCompositePhotoOutput(from photoOutput: PhotoOuput) -> PhotoOuput? {
    switch photoOutput {
    case .basicPhoto(_, let imageData, _):
      guard
        let image = makeCompositeImage(from: imageData),
        let compositeData = Self.makeJPEGData(from: image, originalImageData: imageData)
      else { return nil }

      return .basicPhoto(thumbnail: image, imageData: compositeData, isProxy: false)
    case .livePhoto(_, let imageData, let videoData, _):
      // Live Photo는 still image와 paired video가 같은 content identifier를 가져야 Photos에서 하나의 자산으로 묶인다.
      // 합성 과정에서 still image를 새 JPEG로 다시 쓰기 때문에, 원본의 identifier를 읽어 새 still metadata에 다시 심는다.
      let assetIdentifier = Self.livePhotoAssetIdentifier(from: imageData)
        ?? Self.livePhotoAssetIdentifier(fromVideoData: videoData)

      guard
        let assetIdentifier,
        let image = makeCompositeImage(from: imageData),
        let compositeData = Self.makeJPEGData(
          from: image,
          originalImageData: imageData,
          livePhotoAssetIdentifier: assetIdentifier
        )
      else { return nil }

      return .livePhoto(thumbnail: image, imageData: compositeData, videoData: videoData, isDeferred: false)
    }
  }

  private func snapshot() -> [OverlayStroke] {
    lock.lock()
    let strokes = visibleStrokes
    lock.unlock()
    return strokes
  }

  private func makeCompositeImage(from imageData: Data) -> UIImage? {
    guard let image = UIImage(data: imageData) else { return nil }
    let strokes = snapshot()
    guard !strokes.isEmpty else { return nil }

    let format = UIGraphicsImageRendererFormat()
    format.scale = image.scale
    format.opaque = true

    let imageSize = image.size
    let imageRect = CGRect(origin: .zero, size: imageSize)
    let overlayRect = Self.aspectFitRect(aspectRatio: CGSize(width: 3, height: 4), in: imageRect)
    let lineScale = max(overlayRect.width / 377, overlayRect.height / (377 * 4 / 3))

    return UIGraphicsImageRenderer(size: imageSize, format: format).image { rendererContext in
      image.draw(in: imageRect)

      let context = rendererContext.cgContext
      drawNormalStrokes(strokes.filter { !$0.isMagicPen }, in: context, overlayRect: overlayRect, lineScale: lineScale)
      drawMagicStrokes(
        strokes.filter { $0.isMagicPen },
        in: context,
        imageSize: imageSize,
        overlayRect: overlayRect,
        lineScale: lineScale
      )
    }
  }

  private func drawNormalStrokes(
    _ strokes: [OverlayStroke],
    in context: CGContext,
    overlayRect: CGRect,
    lineScale: CGFloat
  ) {
    for stroke in strokes {
      let path = Self.makePath(points: stroke.points, in: overlayRect)
      Self.stroke(path, in: context, color: .offWhite, width: 10 * lineScale)
      Self.stroke(path, in: context, color: Self.outerColor(for: stroke.author), width: 7 * lineScale)
    }
  }

  private func drawMagicStrokes(
    _ strokes: [OverlayStroke],
    in context: CGContext,
    imageSize: CGSize,
    overlayRect: CGRect,
    lineScale: CGFloat
  ) {
    guard !strokes.isEmpty else { return }

    let blurLayer = makeMagicBlurLayer(
      strokes: strokes,
      imageSize: imageSize,
      overlayRect: overlayRect,
      lineScale: lineScale
    )

    if let blurLayer {
      blurLayer.draw(in: CGRect(origin: .zero, size: imageSize))
    }

    for stroke in strokes {
      let path = Self.makePath(points: stroke.points, in: overlayRect)
      Self.stroke(path, in: context, color: .systemWhite, width: 3 * lineScale)
    }
  }

  private func makeMagicBlurLayer(
    strokes: [OverlayStroke],
    imageSize: CGSize,
    overlayRect: CGRect,
    lineScale: CGFloat
  ) -> UIImage? {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = false

    let sourceImage = UIGraphicsImageRenderer(size: imageSize, format: format).image { rendererContext in
      let context = rendererContext.cgContext

      for stroke in strokes {
        let path = Self.makePath(points: stroke.points, in: overlayRect)
        Self.stroke(path, in: context, color: Self.outerColor(for: stroke.author), width: 10 * lineScale)
        Self.stroke(path, in: context, color: .systemWhite, width: 5 * lineScale)
      }
    }

    guard
      let ciImage = CIImage(image: sourceImage),
      let filter = CIFilter(name: "CIGaussianBlur")
    else { return sourceImage }

    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(4 * lineScale, forKey: kCIInputRadiusKey)

    guard
      let outputImage = filter.outputImage?.cropped(to: ciImage.extent),
      let cgImage = ciContext.createCGImage(outputImage, from: ciImage.extent)
    else { return sourceImage }

    return UIImage(cgImage: cgImage)
  }

  private static func aspectFitRect(aspectRatio: CGSize, in rect: CGRect) -> CGRect {
    let targetRatio = aspectRatio.width / aspectRatio.height
    let rectRatio = rect.width / rect.height

    if rectRatio > targetRatio {
      let width = rect.height * targetRatio
      return CGRect(
        x: rect.midX - width / 2,
        y: rect.minY,
        width: width,
        height: rect.height
      )
    } else {
      let height = rect.width / targetRatio
      return CGRect(
        x: rect.minX,
        y: rect.midY - height / 2,
        width: rect.width,
        height: height
      )
    }
  }

  private static func makePath(points: [CGPoint], in rect: CGRect) -> UIBezierPath {
    let path = UIBezierPath()

    guard let first = points.first else { return path }
    path.move(to: point(from: first, in: rect))

    for point in points.dropFirst() {
      path.addLine(to: self.point(from: point, in: rect))
    }

    return path
  }

  private static func point(from point: CGPoint, in rect: CGRect) -> CGPoint {
    CGPoint(
      x: rect.minX + point.x * rect.width,
      y: rect.minY + point.y * rect.height
    )
  }

  private static func stroke(_ path: UIBezierPath, in context: CGContext, color: UIColor, width: CGFloat) {
    context.saveGState()
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
    context.restoreGState()
  }

  private static func outerColor(for role: Role) -> UIColor {
    switch role {
    case .model:
      return .modelPrimary
    case .photographer:
      return .photographerPrimary
    }
  }

  private static func makeJPEGData(
    from image: UIImage,
    originalImageData: Data,
    livePhotoAssetIdentifier: String? = nil
  ) -> Data? {
    guard let cgImage = image.cgImage else { return nil }

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
      return nil
    }

    // 새 JPEG에도 촬영 시점의 EXIF/MakerApple metadata를 최대한 유지한다.
    // Live Photo content identifier도 이 metadata에 들어가므로 단순 jpegData(compressionQuality:)를 쓰면 안 된다.
    var properties = imageProperties(from: originalImageData)
    properties[kCGImageDestinationLossyCompressionQuality as String] = 0.95
    normalizeOrientation(in: &properties)

    if let livePhotoAssetIdentifier {
      // Apple MakerNote key "17"이 Live Photo still과 video를 연결하는 content identifier다.
      // 이 값이 paired video의 quicktime content.identifier와 맞지 않으면 PHPhotosErrorDomain 3302가 발생한다.
      var makerAppleDictionary = properties[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any] ?? [:]
      makerAppleDictionary["17"] = livePhotoAssetIdentifier
      properties[kCGImagePropertyMakerAppleDictionary as String] = makerAppleDictionary
    }

    CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { return nil }

    return data as Data
  }

  private static func normalizeOrientation(in properties: inout [String: Any]) {
    // UIImage.draw(in:)는 orientation을 적용한 픽셀을 새 이미지에 굽는다.
    // 원본 orientation metadata까지 그대로 복사하면 Photos가 한 번 더 회전시키므로, 새 JPEG는 .up으로 정규화한다.
    properties[kCGImagePropertyOrientation as String] = CGImagePropertyOrientation.up.rawValue

    if var tiffDictionary = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
      tiffDictionary[kCGImagePropertyTIFFOrientation as String] = CGImagePropertyOrientation.up.rawValue
      properties[kCGImagePropertyTIFFDictionary as String] = tiffDictionary
    }
  }

  private static func imageProperties(from imageData: Data) -> [String: Any] {
    guard
      let source = CGImageSourceCreateWithData(imageData as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
    else { return [:] }

    return properties
  }

  private static func livePhotoAssetIdentifier(from imageData: Data) -> String? {
    // AVCapturePhoto.fileDataRepresentation()이 만든 원본 still에는 보통 MakerApple "17" 값이 들어 있다.
    let makerAppleDictionary = imageProperties(from: imageData)[kCGImagePropertyMakerAppleDictionary as String]
      as? [String: Any]

    return makerAppleDictionary?["17"] as? String
  }

  private static func livePhotoAssetIdentifier(fromVideoData videoData: Data) -> String? {
    // deferred/proxy 경로 등에서 still metadata를 읽지 못할 경우를 대비해 paired video의 QuickTime metadata를 fallback으로 사용한다.
    // AVURLAsset은 URL 기반으로 metadata를 읽기 때문에, 받은 Data를 임시 mov 파일로 쓴 뒤 바로 삭제한다.
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
            || item.key as? String == "com.apple.quicktime.content.identifier"
        }?
        .stringValue
    } catch {
      return nil
    }
  }
}
