//
//  GuideVideo.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import Foundation

enum GuideVideo {
  case modelGuide0
  case modelGuide1
  case modelGuide2
  case photographerGuide0
  case photographerGuide1
  case photographerGuide2

  private var videoFileExtension: String { "mov" }

  private var videoFileName: String {
    switch self {
    case .modelGuide0: return "model_guide_0"
    case .modelGuide1: return "model_guide_1"
    case .modelGuide2: return "model_guide_2"
    case .photographerGuide0: return "photographer_guide_0"
    case .photographerGuide1: return "photographer_guide_1"
    case .photographerGuide2: return "photographer_guide_2"
    }
  }

  var videoFileURL: URL? {
    Bundle.main.url(forResource: self.videoFileName, withExtension: videoFileExtension)
  }

  static func getByRoleAndIndex(role: Role, index: Int) -> Self? {
    if role == .model {
      switch index {
      case 0: return .modelGuide0
      case 1: return .modelGuide1
      case 2: return .modelGuide2
      default: return nil
      }
    } else if role == .photographer {
      switch index {
      case 0: return .photographerGuide0
      case 1: return .photographerGuide1
      case 2: return .photographerGuide2
      default: return nil
      }
    }

    return nil
  }
}
