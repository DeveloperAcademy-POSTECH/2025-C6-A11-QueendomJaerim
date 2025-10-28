//
//  GraphicMapper.swift
//  QueenCam
//
//  Created by 임영택 on 10/20/25.
//

import Foundation
import SwiftUI

struct GraphicMapper {
  // MARK: - CGPoint <-> PointPayload
  static func convert(pointPayload: PointPayload) -> CGPoint {
    CGPoint(x: pointPayload.x, y: pointPayload.y)
  }

  static func convert(cgPoint: CGPoint) -> PointPayload {
    PointPayload(x: cgPoint.x, y: cgPoint.y)
  }

  // MARK: - [CGPoint] <-> [PointPayload]
  static func convert(pointsPayload: [PointPayload]) -> [CGPoint] {
    pointsPayload.map { convert(pointPayload: $0) }
  }
  
  static func convert(cgPoints: [CGPoint]) -> [PointPayload] {
    cgPoints.map { convert(cgPoint: $0) }
  }
  
  // MARK: - CGSize <-> SizePayload
  static func convert(sizePayload: SizePayload) -> CGSize {
    CGSize(width: sizePayload.width, height: sizePayload.height)
  }

  static func convert(cgSize: CGSize) -> SizePayload {
    SizePayload(width: cgSize.width, height: cgSize.height)
  }

  // MARK: - Color <-> ColorPayload
  static func convert(colorPayload: ColorPayload) -> Color {
    Color(red: colorPayload.red, green: colorPayload.green, blue: colorPayload.blue, opacity: colorPayload.opacity)
  }

  static func convert(color: Color) -> ColorPayload {
    let uiColor = UIColor(color)

    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return .init(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0)
    }

    return ColorPayload(
      red: Double(red),
      green: Double(green),
      blue: Double(blue),
      opacity: Double(alpha)
    )
  }
}
