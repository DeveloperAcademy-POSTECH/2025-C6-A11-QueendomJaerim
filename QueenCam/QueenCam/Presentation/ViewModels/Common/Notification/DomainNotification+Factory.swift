//
//  DomainNotification+Factory.swift
//  QueenCam
//
//  Created by 임영택 on 10/31/25.
//

import Foundation
import SwiftUI

extension DomainNotification {
  static func make(type: DomainNotificationType) -> DomainNotification {
    let preset = type.preset
    
    return .init(
      message: preset.message,
      isImportant: preset.isImportant,
      showingTime: preset.showingTime
    )
  }
  
  struct Preset {
    let message: LocalizedStringKey
    let isImportant: Bool
    let showingTime: TimeInterval?
  }
  
  enum DomainNotificationType {
    case ready
    case flashOn
    case flashAuto
    case sharingFrameGuideStarted
    case counterpartEditingFrameGuide
    case myEditingFrameGuide
    
    var preset: Preset {
      switch self {
      case .ready: return .init(message: "기기를 연결해 촬영해보세요", isImportant: false, showingTime: nil)
      case .flashOn: return .init(message: "플래시 켬", isImportant: true, showingTime: 1)
      case .flashAuto: return .init(message: "플래시 자동", isImportant: true, showingTime: 1)
      case .sharingFrameGuideStarted: return .init(message: "프레임 가이드를 공유합니다.", isImportant: false, showingTime: 2)
      case .counterpartEditingFrameGuide: return .init(message: "상대가 프레임을 수정중입니다.", isImportant: false, showingTime: 2)
      case .myEditingFrameGuide: return .init(message: "내가 그린 가이드를 공유합니다.", isImportant: false, showingTime: 2)
      }
    }
  }
}
