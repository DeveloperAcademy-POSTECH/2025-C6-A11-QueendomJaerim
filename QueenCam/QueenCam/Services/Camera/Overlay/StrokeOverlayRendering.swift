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
  /// 프리뷰 기준 정규화 좌표를 방향이 적용된 저장 사진의 정규화 좌표로 바꾼다.
  /// 화면은 세로로 고정이라 가로로 찍은 사진은 시계 방향으로 `quarterTurns`번 돌려야 같은 피사체 위에 온다.
  static func photoPoint(fromPreview point: CGPoint, ratio: PhotoAspectRatio, quarterTurns: Int) -> CGPoint {
    let portraitPoint = PhotoAspectRatioGeometry.outputPoint(fromPreview: point, ratio: ratio)

    switch ((quarterTurns % 4) + 4) % 4 {
    case 1:
      return CGPoint(x: 1 - portraitPoint.y, y: portraitPoint.x)
    case 2:
      return CGPoint(x: 1 - portraitPoint.x, y: 1 - portraitPoint.y)
    case 3:
      return CGPoint(x: portraitPoint.y, y: 1 - portraitPoint.x)
    default:
      return portraitPoint
    }
  }

  /// 사진 연결의 촬영 각도를 회전 수로 바꾼다. 세로 화면과 같은 90도가 0번이다.
  /// 시계 방향이 맞는지는 실기기 촬영으로 확인한다.
  static func quarterTurns(forVideoRotationAngle angle: CGFloat) -> Int {
    let turns = Int(((angle - 90) / 90).rounded())
    return ((turns % 4) + 4) % 4
  }

  /// 화면에서 보인 두께와 같아지도록 사진 픽셀에 곱할 배율.
  /// 세 비율 모두 프리뷰 폭이 저장 사진의 짧은 변과 같다.
  static func lineScale(imageSize: CGSize, previewWidth: CGFloat) -> CGFloat {
    guard previewWidth.isFinite, previewWidth > 0 else { return 1 }

    return min(imageSize.width, imageSize.height) / previewWidth
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
