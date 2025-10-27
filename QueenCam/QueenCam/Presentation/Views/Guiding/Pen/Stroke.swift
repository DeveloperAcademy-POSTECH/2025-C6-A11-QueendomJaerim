//
//  Pen.swift
//  QueenCam
//
//  Created by 윤보라 on 10/15/25.
//

import Foundation

//하나의 획(펜으로 그린 하나의 선)
struct Stroke: Identifiable, Hashable {
  var id = UUID()
  var points: [CGPoint]  // 선을 구성하는 점(x,y)들
  init(points: [CGPoint]) {
    self.points = points
  }
  func absolutePoints(in size: CGSize) -> [CGPoint] {
    points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height)}
  }
}
