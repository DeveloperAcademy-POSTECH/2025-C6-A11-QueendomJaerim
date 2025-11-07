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
    case flashOff
    case liveOn
    case liveOff
    case sharingFrameGuideStarted
    case counterpartEditingFrameGuide
    case myEditingFrameGuide
    case turnOnGuidingFirstWithFrame
    case turnOnGuidingFirstWithPen
    case turnOnGuidingFirstWithMagicPen
    case turnOffGuiding
    case turnOnGuiding
    
    var preset: Preset {
      switch self {
      case .ready:
        return .init(message: "친구와 연결해보세요.", isImportant: false, showingTime: nil)
      case .flashOn:
        return .init(message: "플래시 켬", isImportant: true, showingTime: 1)
      case .flashAuto:
        return .init(message: "플래시 자동", isImportant: true, showingTime: 1)
      case .flashOff:
        return .init(message: "플래시 끔", isImportant: false, showingTime: 1)
      case .liveOn:
        return .init(message: "LIVE 켬", isImportant: true, showingTime: 1)
      case .liveOff:
        return .init(message: "LIVE 끔", isImportant: false, showingTime: 1)
      case .sharingFrameGuideStarted:
        return .init(message: "프레임 가이드를 공유합니다.", isImportant: false, showingTime: 2)
      case .counterpartEditingFrameGuide:
        return .init(message: "상대가 프레임을 수정중입니다.", isImportant: false, showingTime: 2)
      case .myEditingFrameGuide:
        return .init(message: "내가 그린 가이드를 공유합니다.", isImportant: false, showingTime: 2)
      case .turnOnGuidingFirstWithFrame:
        return .init(message: "프레임을 사용하려면 먼저 눈을 켜주세요.", isImportant: false, showingTime: 2)
        
      case .turnOnGuidingFirstWithPen:
        return .init(message: "펜을 사용하려면 먼저 눈을 켜주세요.", isImportant: false, showingTime: 2)
        
      case .turnOnGuidingFirstWithMagicPen:
        return .init(message: "매직펜을 사용하려면 먼저 눈을 켜주세요.", isImportant: false, showingTime: 2)
      case .turnOffGuiding:
        return .init(message: "모든 가이드를 숨깁니다.", isImportant: false, showingTime: 2)
      case .turnOnGuiding:
        return .init(message: "가이드가 보여집니다.", isImportant: false, showingTime: 2)
      }
    }
  }
}
