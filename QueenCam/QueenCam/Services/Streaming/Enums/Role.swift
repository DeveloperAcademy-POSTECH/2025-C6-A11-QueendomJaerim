//
//  Role.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation

enum Role: CustomDebugStringConvertible, Codable {
  case photographer
  case model

  var debugDescription: String {
    switch self {
    case .photographer: return "Photographer"
    case .model: return "Model"
    }
  }

  var counterpart: Role {
    switch self {
    case .photographer: return .model
    case .model: return .photographer
    }
  }
}
