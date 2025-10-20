//
//  FrameMapper.swift
//  QueenCam
//
//  Created by 임영택 on 10/20/25.
//

import Foundation
import SwiftUI

struct FrameMapper {
  static func convert(payload: FrameEventType.FramePayload) -> Frame {
    Frame(
      id: payload.id,
      rect: CGRect(
        origin: convert(pointPayload: payload.origin),
        size: convert(sizePayload: payload.size)
      ),
      color: convert(colorPayload: payload.color)
    )
  }

  static func convert(frame: Frame) -> FrameEventType.FramePayload {
    FrameEventType.FramePayload(
      id: frame.id,
      origin: convert(cgPoint: frame.rect.origin),
      size: convert(cgSize: frame.rect.size),
      color: convert(color: frame.color)
    )
  }

  // MARK: - CGPoint <-> PointPayload
  private static func convert(pointPayload: FrameEventType.PointPayload) -> CGPoint {
    CGPoint(x: pointPayload.x, y: pointPayload.y)
  }

  private static func convert(cgPoint: CGPoint) -> FrameEventType.PointPayload {
    FrameEventType.PointPayload(x: cgPoint.x, y: cgPoint.y)
  }

  // MARK: - CGSize <-> SizePayload
  private static func convert(sizePayload: FrameEventType.SizePayload) -> CGSize {
    CGSize(width: sizePayload.width, height: sizePayload.height)
  }

  private static func convert(cgSize: CGSize) -> FrameEventType.SizePayload {
    FrameEventType.SizePayload(width: cgSize.width, height: cgSize.height)
  }

  // MARK: - Color <-> ColorPayload
  private static func convert(colorPayload: FrameEventType.ColorPayload) -> Color {
    Color(red: colorPayload.red, green: colorPayload.green, blue: colorPayload.blue, opacity: colorPayload.opacity)
  }

  private static func convert(color: Color) -> FrameEventType.ColorPayload {
    let uiColor = UIColor(color)

    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return .init(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0)
    }

    return FrameEventType.ColorPayload(
      red: Double(red),
      green: Double(green),
      blue: Double(blue),
      opacity: Double(alpha)
    )
  }
}
