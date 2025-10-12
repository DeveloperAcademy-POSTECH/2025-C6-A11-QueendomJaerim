//
//  PreviewFrameQuality.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation

enum PreviewFrameQuality: Sendable {
  case high
  case medium
  case low

  var scale: CGFloat {
    switch self {
    case .high: return 1.0
    case .medium: return 0.7
    case .low: return 0.5
    }
  }

  var jpegQuality: CGFloat {
    switch self {
    case .high:   return 0.8
    case .medium: return 0.4
    case .low:    return 0.2
    }
  }

  var displayLabel: String {
    switch self {
    case .high:   return "High"
    case .medium: return "Medium"
    case .low:    return "Low"
    }
  }

  func getBetter() -> PreviewFrameQuality {
    switch self {
    case .high: return .high // high -> high
    case .medium: return .high
    case .low: return .medium
    }
  }

  func getWorse() -> PreviewFrameQuality {
    switch self {
    case .high: return .medium
    case .medium: return .low
    case .low: return .low // low -> low
    }
  }
}

nonisolated extension PreviewFrameQuality: Codable {
}
