//
//  PenMapper.swift
//  QueenCam
//
//  Created by Bora Yun on 10/28/25.
//

import Foundation

struct PenMapper {
  static func convert(payload: PenPayload) -> Stroke {
    Stroke(
      id: payload.id,
      points: GraphicMapper.convert(pointsPayload: payload.points)
    )
  }
  
  static func convert(stroke: Stroke) -> PenPayload {
    PenPayload(id: stroke.id, points: GraphicMapper.convert(cgPoints: stroke.points))
  }
}
