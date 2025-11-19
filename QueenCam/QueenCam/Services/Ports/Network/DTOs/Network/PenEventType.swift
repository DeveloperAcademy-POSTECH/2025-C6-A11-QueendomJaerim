//
//  PenEventType.swift
//  QueenCam
//
//  Created by Bora Yun on 10/28/25.
//

import CoreGraphics
import Foundation

enum PenEventType: Codable, Sendable {
  /// 새로운 가이딩 펜을 추가한다
  case add(PenPayload)
  /// 이전에 추가된 가이딩 펜을 바꾼다
  case replace(PenPayload)
  /// 이전에 추가된 가이딩 펜을 지운다
  case delete(id: UUID)
  /// 이전에 추가된 모든 가이딩 펜을 지운다
  case reset
}

struct PenPayload: Codable, Sendable {
  /// 가이딩 펜의 획 식별자
  let id: UUID
  /// 가이딩 펜의 획(stroke) 점들의 배열
  let points: [PointPayload]
  /// 매직펜 여부
  let isMagicPen: Bool
  /// 작성자 역할
  let author: Role
  /// 매직펜 그린 종료 시점
  var endDrawing: Bool
}
