//
//  AnalyticsScreen.swift
//  QueenCam
//
//  Created by 임영택 on 4/4/26.
//

import Foundation

/// GA 이벤트 기록과 함께 추적할 현재 스크린을 정의하는 열거형
enum AnalyticsScreen {
  /// 카메라 뷰
  case camera
  /// 프리뷰 (스트리밍 뷰)
  case preview
  /// 연결/페어링 시트
  case connectionSheet
  /// 포토 시트
  case photoSheet
  /// 설정 화면
  case settings

  var displayName: String {
    switch self {
    case .camera: return "camera"
    case .preview: return "preview"
    case .connectionSheet: return "connectionSheet"
    case .photoSheet: return "photoSheet"
    case .settings: return "settings"
    }
  }
}

/// GA 이벤트 기록과 함께 추적할 현재 스크린 이동 동작을 정의하는 열거형
enum AnalyticsScreenAction {
  case didAppear(_ screen: AnalyticsScreen, from: Any.Type, id: UUID)
  case didDisappear(_ screen: AnalyticsScreen, from: Any.Type, id: UUID)
  case reset
}

/// 화면 이름과 구체적인 뷰의 타입 정보를 함께 담는 구조체
struct AnalyticsScreenData {
  let screen: AnalyticsScreen
  let className: String
  let id: UUID
}
