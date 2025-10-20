//
//  FrameEventType.swift
//  QueenCam
//
//  Created by 임영택 on 10/20/25.
//

import Foundation

enum FrameEventType: Codable, Sendable {
  case add(FramePayload)
  case replace(FramePayload)
  case delete(id: UUID)
  case deleteAll
}

struct FramePayload: Codable, Sendable {
  let id: UUID
  let origin: PointPayload
  let size: SizePayload
  let color: ColorPayload
}

struct PointPayload: Codable, Sendable {
  let x: Double
  let y: Double
}

struct SizePayload: Codable, Sendable {
  let width: Double
  let height: Double
}

struct ColorPayload: Codable, Sendable {
  let red: Double
  let green: Double
  let blue: Double
  let opacity: Double
}
