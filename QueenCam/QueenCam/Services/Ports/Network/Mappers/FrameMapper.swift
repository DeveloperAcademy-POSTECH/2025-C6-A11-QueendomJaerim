//
//  FrameMapper.swift
//  QueenCam
//
//  Created by 임영택 on 10/20/25.
//

import Foundation

struct FrameMapper {
  static func convert(payload: FramePayload) -> Frame {
    Frame(
      id: payload.id,
      rect: CGRect(
        origin: GraphicMapper.convert(pointPayload: payload.origin),
        size: GraphicMapper.convert(sizePayload: payload.size)
      )    )
  }

  static func convert(frame: Frame) -> FramePayload {
    FramePayload(
      id: frame.id,
      origin: GraphicMapper.convert(cgPoint: frame.rect.origin),
      size: GraphicMapper.convert(cgSize: frame.rect.size)
    )
  }
}
