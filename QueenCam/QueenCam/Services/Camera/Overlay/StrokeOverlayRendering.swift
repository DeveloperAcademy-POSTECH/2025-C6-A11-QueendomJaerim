//
//  StrokeOverlayRendering.swift
//  QueenCam
//
//  Created by 임영택 on 6/21/26.
//

import CoreGraphics
import SwiftUI
import UIKit

struct StrokeRenderStyle {
  let backgroundColor: Color
  let foregroundColor: Color
  let backgroundUIColor: UIColor
  let foregroundUIColor: UIColor
  let backgroundLineWidth: CGFloat
  let foregroundLineWidth: CGFloat

  var backgroundStrokeStyle: StrokeStyle {
    StrokeStyle(lineWidth: backgroundLineWidth, lineCap: .round, lineJoin: .round)
  }

  var foregroundStrokeStyle: StrokeStyle {
    StrokeStyle(lineWidth: foregroundLineWidth, lineCap: .round, lineJoin: .round)
  }

  func scaled(by scale: CGFloat) -> StrokeRenderStyle {
    StrokeRenderStyle(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      backgroundUIColor: backgroundUIColor,
      foregroundUIColor: foregroundUIColor,
      backgroundLineWidth: backgroundLineWidth * scale,
      foregroundLineWidth: foregroundLineWidth * scale
    )
  }
}

enum StrokeRenderStyleResolver {
  private static let normalBackgroundLineWidth: CGFloat = 10
  private static let normalForegroundLineWidth: CGFloat = 7

  static func normalStrokeStyle(for author: Role, lineScale: CGFloat = 1) -> StrokeRenderStyle {
    StrokeRenderStyle(
      backgroundColor: .offWhite,
      foregroundColor: foregroundColor(for: author),
      backgroundUIColor: .offWhite,
      foregroundUIColor: foregroundUIColor(for: author),
      backgroundLineWidth: normalBackgroundLineWidth * lineScale,
      foregroundLineWidth: normalForegroundLineWidth * lineScale
    )
  }

  private static func foregroundColor(for author: Role) -> Color {
    switch author {
    case .model:
      return .modelPrimary
    case .photographer:
      return .photographerPrimary
    }
  }

  private static func foregroundUIColor(for author: Role) -> UIColor {
    switch author {
    case .model:
      return .modelPrimary
    case .photographer:
      return .photographerPrimary
    }
  }
}

enum StrokeOverlayGeometry {
  static let logicalCanvasAspectRatio = CGSize(width: 3, height: 4)

  // CameraPreviewArea가 iPhone에서 기준으로 쓰는 3:4 캔버스 폭이다.
  // 사진 원본은 기기/방향/해상도에 따라 크기가 달라서, 저장 합성 시에는 이 논리 캔버스를 원본 이미지에 aspect-fit한다.
  private static let logicalCanvasWidth: CGFloat = 377

  static func lineScale(for overlayRect: CGRect) -> CGFloat {
    max(
      overlayRect.width / logicalCanvasWidth,
      overlayRect.height / (logicalCanvasWidth * logicalCanvasAspectRatio.height / logicalCanvasAspectRatio.width)
    )
  }

  static func aspectFitRect(aspectRatio: CGSize = logicalCanvasAspectRatio, in rect: CGRect) -> CGRect {
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

  static func point(from normalizedPoint: CGPoint, in rect: CGRect) -> CGPoint {
    CGPoint(
      x: rect.minX + normalizedPoint.x * rect.width,
      y: rect.minY + normalizedPoint.y * rect.height
    )
  }

  static func path(from normalizedPoints: [CGPoint], in size: CGSize) -> Path {
    var path = Path()
    path.addLines(normalizedPoints.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) })
    return path
  }

  static func bezierPath(from normalizedPoints: [CGPoint], in rect: CGRect) -> UIBezierPath {
    let path = UIBezierPath()

    guard let first = normalizedPoints.first else { return path }
    path.move(to: point(from: first, in: rect))

    for point in normalizedPoints.dropFirst() {
      path.addLine(to: self.point(from: point, in: rect))
    }

    return path
  }
}
