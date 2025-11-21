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
    // 프레임
    /// 사용자가 새로운 프레임 생성 (최초 1회)
    case createdFrameGuide
    /// 상대가 프레임 생성 (최초 1회)
    case peerCreatedFrameGuide
    /// 프레임이 생성된 상태에서, 상대가 프레임 제어 모드 진입
    case peerEditingFrameGuide
    ///  상대가 프레임 생성 (최초 1회)
    case peerDeletedFrameGuide
    // 레퍼런스
    /// 레퍼런스가 없는 상황에서,  사용자가 새로운 레퍼런스를 등록했을 때 (최초 1회)
    case registerFirstReference
    /// 레퍼런스가 없는 상황에서, 상대가 새로운 레퍼런스를 등록했을 때 (최초1회)
    case peerRegisterFirstReference
    /// 레퍼런스가 있는 상황에서 사용자가 새로운 레퍼런스 등록했을 때
    case registerNewReference
    /// 레퍼런스가 있는 상황에서, 상대가 새로운 레퍼런스 등록했을 때
    case peerRegisterNewReference
    /// 사용자가 레퍼런스 삭제시
    case deleteReference
    /// 상대가 레퍼런스 삭제시
    case peerDeleteReference
    /// 가이드툴 사용 중, 레퍼런스 확대 (최초 1회)
    case toolUsingEnlargeReference
    // 펜 + 매직펜
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
    /// 역할이 스위치되었을 때
    case swapRole
    /// 연결이 종료되었을 때
    case disconnected

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
      case .toolUsingEnlargeReference:
        return .init(message: "참고 이미지를 확대하면 툴이 해제됩니다.", isImportant: false, showingTime: 2)
      // 프레임
      case .createdFrameGuide:
        return .init(message: "가이드 프레임을 생성했어요.", isImportant: true, showingTime: 1)
      case .peerCreatedFrameGuide:
        return .init(message: "친구가 가이드 프레임을 생성했어요.", isImportant: true, showingTime: 1)
      case .peerEditingFrameGuide:
        return .init(message: "친구가 프레임을 수정하고 있어요.", isImportant: true, showingTime: 1)
      case .peerDeletedFrameGuide:
        return .init(message: "친구가 프레임을 삭제했어요.", isImportant: true, showingTime: 1)
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
    
      case .captureLivePhoto:
        return .init(message: "LIVE", isImportant: true, showingTime: 2)
      // 연결
      case .swapRole:
        return .init(message: "친구와 역할이 서로 바뀌었어요.", isImportant: false, showingTime: 2)
      case .disconnected:
        return .init(message: "연결이 종료되었어요.", isImportant: false, showingTime: 2)
      }
    }
  }
}
