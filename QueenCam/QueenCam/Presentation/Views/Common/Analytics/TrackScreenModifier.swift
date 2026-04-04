//
//  TrackScreenModifier.swift
//  QueenCam
//
//  Created by 임영택 on 4/4/26.
//

import SwiftUI

/// SwiftUI 뷰에서 화면 트래킹을 선언적으로 수행하기 위한 모디파이어
struct TrackScreenModifier: ViewModifier {
  let screen: AnalyticsScreen
  let viewType: Any.Type

  @State private var instanceId = UUID()

  private let logger = QueenLogger(category: "TrackScreenModifier")

  func body(content: Content) -> some View {
    content
      .onAppear {
        logger.debug("onAppear: screen=\(screen.displayName), view=\(viewType), id=\(instanceId)")
        AnalyticsService.sendScreenEvent(.didAppear(screen, from: viewType, id: instanceId))
      }
      .onDisappear {
        logger.debug("onDisappear: screen=\(screen.displayName), view=\(viewType), id=\(instanceId)")
        AnalyticsService.sendScreenEvent(.didDisappear(screen, from: viewType, id: instanceId))
      }
  }
}

extension View {
  /**
   해당 뷰가 화면에 나타날 때 GA 화면 트래킹 이벤트를 발행합니다.
   - Parameters:
     - screen: 추적할 화면 식별자
     - viewType: 추적에 기록할 뷰의 타입 (예: Self.self 또는 특정 뷰 클래스)
   */
  func trackScreen(_ screen: AnalyticsScreen, _ viewType: Any.Type) -> some View {
    self.modifier(TrackScreenModifier(screen: screen, viewType: viewType))
  }
}
