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
    /// 상대가 프레임을 수정하고 있을 때 (최초 1회)
    case peerEditingFrameGuide
    /// 상대가 가이드 프레임을 생성했을 때 (최초 1회)
    case peerCreateFrameGuide
    /// 사용자가 가이드 프레임을 껐을 때 (최초 1회)
    case closeFrameGuide
    /// 상대가 가이드 프레임을 껐을 때 (최초 1회)
    case peerCloseFrameGuide
    /// 상대가 프레임 수정 모드에 돌입 했을 때 (최초 1회)
    case peerFirstEditMode
    /// 사용자가 프레임 수정 모드에 돌입 했을 때 (최초 1회)
    case firstEditMode

    /// 상대가 가이드 프레임을 생성했을 때 (최초 1회)
    /// 사용자가 가이드 프레임을 껐을 때 (최초 1회)
    /// 상대가 가이드 프레임을 껐을 때 (최초 1회)
    /// 상대가 프레임 수정 모드에 돌입 했을 때 (최초 1회)
    /// 사용자가 프레임 수정 모드에 돌입 했을 때 (최초 1회)
    /// 레퍼런스가 없는 상황에서,  사용자가 새로운 레퍼런스를 등록했을 때
    case registerFirstReference
    /// 레퍼런스가 없는 상황에서, 상대가 새로운 레퍼런스를 등록했을 때
    case peerRegisterFirstReference
    /// 레퍼런스가 있는 상황에서 사용자가 새로운 레퍼런스 등록했을 때
    case registerNewReference
    /// 레퍼런스가 있는 상황에서, 상대가 새로운 레퍼런스 등록했을 때
    case peerRegisterNewReference
    /// 사용자가 레퍼런스 삭제시
    case deleteReference
    /// 상대가 레퍼런스 삭제시
    case peerDeleteReference

    /// 펜툴을 처음 선택한 경우 (최초 1회)
    case firstPenToolSelected
    /// 펜의 지우개를 사용할 때
    case penEraserSelected
    /// 매직펜툴을 처음 선택한 경우 (최초 1회)
    case firstMagicToolSelected
    /// Photos 진입 시. 바텀시트로 화면 반만 덮었을 때.
    case photosPickerShowing
    /// 라이브 포토로 설정하고 촬영할 때
    case captureLivePhoto

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
      // 레퍼런스
      case .registerFirstReference:
        return .init(message: "친구에게도 참고 이미지가 공유되었어요", isImportant: false, showingTime: 2)
      case .peerRegisterFirstReference:
        return .init(message: "친구가 참고 이미지를 등록했어요.", isImportant: false, showingTime: 2)
      case .registerNewReference:
        return .init(message: "새로운 참고 이미지를 등록했어요.", isImportant: false, showingTime: 2)
      case .peerRegisterNewReference:
        return .init(message: "친구가 새로운 참고 이미지를 등록했어요.", isImportant: false, showingTime: 2)
      case .deleteReference:
        return .init(message: "참고 이미지를 삭제했어요.", isImportant: false, showingTime: 2)
      case .peerDeleteReference:
        return .init(message: "친구가 참고 이미지를 삭제했어요.", isImportant: false, showingTime: 2)
      case .photosPickerShowing:
        return .init(message: "함께 참고할 이미지를 등록할 수 있습니다.", isImportant: false, showingTime: nil)
      // 펜 + 매직펜
      case .firstPenToolSelected:
        return .init(message: "펜으로 가이드를 그립니다.", isImportant: false, showingTime: 2)
      case .penEraserSelected:
        return .init(message: "깔끔하게 지웠어요.", isImportant: false, showingTime: 2)
      case .firstMagicToolSelected:
        return .init(message: "지우지 않아도 사라지는 펜입니다.", isImportant: false, showingTime: 2)
      // 프레임
      case .peerEditingFrameGuide:
        return .init(message: "친구가 프레임을 수정하고 있어요.", isImportant: false, showingTime: 2)
      case .peerCreateFrameGuide:
        return .init(message: "친구가 가이드 프레임을 생성했어요.", isImportant: false, showingTime: 2)
      case .closeFrameGuide:
        return .init(message: "친구에게도 프레임이 꺼집니다.", isImportant: false, showingTime: 2)
      case .peerCloseFrameGuide:
        return .init(message: "친구가 프레임을 껐어요.", isImportant: false, showingTime: 2)
      case .peerFirstEditMode:
        return .init(message: "친구가 프레임을 수정하고 있어요.", isImportant: false, showingTime: 2)
      case .firstEditMode:
        return .init(message: "프레임의 비율을 조정합니다.", isImportant: false, showingTime: 2)
      case .captureLivePhoto:
        return .init(message: "LIVE", isImportant: true, showingTime: 2)
      }
    }
  }
}
