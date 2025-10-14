//
//  Role.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation

enum Role: CustomDebugStringConvertible {
  case photographer
  case model

  var debugDescription: String {
    switch self {
    case .photographer: return "Photographer"
    case .model: return "Model"
    }
  }
}
