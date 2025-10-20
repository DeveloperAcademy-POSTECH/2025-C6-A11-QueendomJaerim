//
//  PointPayload.swift
//  QueenCam
//
//  Created by 임영택 on 10/20/25.
//

/// CGPoint를 전송하기 위한 순수한 DTO
struct PointPayload: Codable, Sendable {
  let x: Double
  let y: Double
}
