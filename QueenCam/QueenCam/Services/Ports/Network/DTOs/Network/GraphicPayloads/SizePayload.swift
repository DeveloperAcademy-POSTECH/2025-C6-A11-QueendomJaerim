//
//  SizePayload.swift
//  QueenCam
//
//  Created by 임영택 on 10/20/25.
//

/// CGSize를 전송하기 위한 순수한 DTO
struct SizePayload: Codable, Sendable {
  let width: Double
  let height: Double
}
