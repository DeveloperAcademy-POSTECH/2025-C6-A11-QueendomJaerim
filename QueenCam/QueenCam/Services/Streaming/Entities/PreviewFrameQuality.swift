//
//  PreviewFrameQuality.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Foundation

nonisolated enum PreviewFrameQuality: Sendable, Codable {
  case high
  case medium
  case low
  case veryLow

  var scale: CGFloat {
    switch self {
    case .high: return 1.00
    case .medium: return 0.85
    case .low: return 0.75
    case .veryLow: return 0.50
    }
  }

  var displayLabel: String {
    switch self {
    case .high: return "High"
    case .medium: return "Medium"
    case .low: return "Low"
    case .veryLow: return "Very Low"
    }
  }

  func getBetter() -> PreviewFrameQuality {
    switch self {
    case .high: return .high  // high -> high
    case .medium: return .high
    case .low: return .medium
    case .veryLow: return .low
    }
  }

  func getWorse() -> PreviewFrameQuality {
    switch self {
    case .high: return .medium
    case .medium: return .low
    case .low: return .veryLow
    case .veryLow: return .veryLow  // veryLow -> veryLow
    }
  }
}
