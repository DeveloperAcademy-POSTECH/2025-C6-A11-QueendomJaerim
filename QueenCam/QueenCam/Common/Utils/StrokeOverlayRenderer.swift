//
//  StrokeOverlayRenderer.swift
//  QueenCam
//
//  Created by 임영택 on 6/14/26.
//

import SwiftUI
import UIKit

enum StrokeOverlayRenderer {
  static let logicalCanvasAspectRatio = CGSize(width: 3, height: 4)

  // CameraPreviewArea가 iPhone에서 기준으로 쓰는 3:4 캔버스 폭이다.
  // 실제 촬영 이미지는 이 논리 캔버스를 aspect-fit한 영역에 맞춰 stroke 좌표를 투영한다.
  private static let logicalCanvasWidth: CGFloat = 377
  private static let normalBackgroundLineWidth: CGFloat = 10
  private static let normalForegroundLineWidth: CGFloat = 7

  static func lineScale(for overlayRect: CGRect) -> CGFloat {
    max(
      overlayRect.width / logicalCanvasWidth,
      overlayRect.height / (logicalCanvasWidth * logicalCanvasAspectRatio.height / logicalCanvasAspectRatio.width)
    )
  }

  static func aspectFitRect(aspectRatio: CGSize, in rect: CGRect) -> CGRect {
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

  static func makePath(points: [CGPoint], in size: CGSize) -> Path {
    var path = Path()
    path.addLines(points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) })
    return path
  }

  static func drawNormalStroke(
    points: [CGPoint],
    author: Role,
    in context: GraphicsContext,
    size: CGSize,
    lineScale: CGFloat = 1
  ) {
    let path = makePath(points: points, in: size)
    context.stroke(
      path,
      with: .color(.offWhite),
      style: normalBackgroundStyle(lineScale: lineScale)
    )
    context.stroke(
      path,
      with: .color(.guidingStrokeOuter(for: author)),
      style: normalForegroundStyle(lineScale: lineScale)
    )
  }

  static func drawNormalStroke(
    points: [CGPoint],
    author: Role,
    in context: CGContext,
    overlayRect: CGRect,
    lineScale: CGFloat
  ) {
    let path = makeBezierPath(points: points, in: overlayRect)
    stroke(path, in: context, color: .offWhite, width: normalBackgroundLineWidth * lineScale)
    stroke(path, in: context, color: .guidingStrokeOuter(for: author), width: normalForegroundLineWidth * lineScale)
  }

  private static func normalBackgroundStyle(lineScale: CGFloat) -> StrokeStyle {
    StrokeStyle(
      lineWidth: normalBackgroundLineWidth * lineScale,
      lineCap: .round,
      lineJoin: .round
    )
  }

  private static func normalForegroundStyle(lineScale: CGFloat) -> StrokeStyle {
    StrokeStyle(
      lineWidth: normalForegroundLineWidth * lineScale,
      lineCap: .round,
      lineJoin: .round
    )
  }

  private static func makeBezierPath(points: [CGPoint], in rect: CGRect) -> UIBezierPath {
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
}

