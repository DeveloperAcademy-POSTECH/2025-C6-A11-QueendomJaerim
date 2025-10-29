//
//  Role.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation

enum Role: String, Codable, CustomDebugStringConvertible {
  case photographer
  case model

  var debugDescription: String {
    switch self {
    case .photographer: return "Photographer"
    case .model: return "Model"
    }
  }

  var displayName: String {
    switch self {
    case .photographer: return "작가"
    case .model: return "모델"
    }
  }
}
