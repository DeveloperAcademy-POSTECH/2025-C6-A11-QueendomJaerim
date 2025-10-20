//
//  ColorPayload.swift
//  QueenCam
//
//  Created by 임영택 on 10/20/25.
//

/// SwiftUI의 Color나 UIKit의 UIColor를 전송하기 위한 순수한 DTO
struct ColorPayload: Codable, Sendable {
  let red: Double
  let green: Double
  let blue: Double
  let opacity: Double
}
