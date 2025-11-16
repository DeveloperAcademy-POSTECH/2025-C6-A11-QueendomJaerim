//
//  FrameEventType.swift
//  QueenCam
//
//  Created by 임영택 on 10/20/25.
//

import CoreGraphics
import Foundation

enum FrameEventType: Codable, Sendable {
  /// 새로운 가이딩 프레임을 추가한다
  case add(FramePayload)
  /// 이전에 추가된 가이딩 프레임을 바꾼다
  case replace(FramePayload)
  /// 모든 가이딩 프레임을 지운다
  case deleteAll
}

struct FramePayload: Codable, Sendable {
  /// 가이딩 프레임 식별자
  let id: UUID
  /// 가이딩 프레임 사각형의 원점
  let origin: PointPayload
  /// 가이딩 프레임 사각형의 크기
  let size: SizePayload
}
