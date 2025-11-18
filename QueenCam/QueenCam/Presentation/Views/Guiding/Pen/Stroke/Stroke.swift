//
//  Pen.swift
//  QueenCam
//
//  Created by 윤보라 on 10/15/25.
//

import Foundation

// 하나의 획(펜으로 그린 하나의 선)
struct Stroke: Identifiable, Hashable, Equatable {
  var id: UUID
  var points: [CGPoint]
  /// 매직펜 여부
  var isMagicPen: Bool = false
  /// Stroke 생성자의 역할 - 역할 변경시 Reset 예정
  let author: Role
  /// 매직펜 그리기 종료 시점
  var endDrawing: Date?

  init(id: UUID = UUID(), points: [CGPoint] = [], isMagicPen: Bool, author: Role, endDrawing: Date?) {
    self.id = id
    self.points = points
    self.isMagicPen = isMagicPen
    self.author = author
    self.endDrawing = endDrawing
  }

  func absolutePoints(in size: CGSize) -> [CGPoint] {
    points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
  }
}
