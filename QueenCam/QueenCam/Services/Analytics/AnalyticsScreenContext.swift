//
//  AnalyticsScreenTracker.swift
//  QueenCam
//
//  Created by 임영택 on 4/4/26.
//

import Foundation
import SwiftUI

/// GA 이벤트 기록과 함께 추적할 현재 스크린을 스택으로 관리하는 객체
final class AnalyticsScreenContext {
  private var screenStack: [AnalyticsScreenData]

  weak var delegate: AnalyticsScreenContextDelegate?

  init(screenStack: [AnalyticsScreenData] = []) {
    self.screenStack = screenStack
  }

  /**
   화면 나타남
   현재 화면을 이벤트 트래킹의 관점에서 식별하는 열거형과 함께 구체적인 뷰 클래스, 인스턴스 ID를 전달한다
   */
  func didAppear(_ screen: AnalyticsScreen, from viewType: Any.Type, id: UUID) {
    let lastData = screenStack.last
    let className = String(describing: viewType)
    let newData = AnalyticsScreenData(screen: screen, className: className, id: id)

    screenStack.append(newData)
    delegate?.didChangeScreen(to: newData, from: lastData)
  }

  /**
   화면 사라짐
   고유 ID를 이용해 특정 화면 인스턴스를 추적 목록에서 제거한다.
   */
  func didDisappear(_ screen: AnalyticsScreen, from viewType: Any.Type, id: UUID) -> AnalyticsScreenData? {
    if let index = screenStack.lastIndex(where: { $0.id == id }) {
      let removedData = screenStack.remove(at: index)
      // 현재 보고 있는 화면이 바뀐 경우에만 델리게이트 알림
      if index == screenStack.count {
        delegate?.didChangeScreen(to: screenStack.last, from: removedData)
      }
      return removedData
    }

    return nil
  }
  func reset() {
    let lastData = screenStack.last
    screenStack.removeAll()
    delegate?.didChangeScreen(to: nil, from: lastData)
  }

  func getLastScreen() -> AnalyticsScreenData? {
    screenStack.last
  }
}

protocol AnalyticsScreenContextDelegate: AnyObject {
  /**
   스크린 컨텍스트가 변경되면 알리고, 스크린 변경 이벤트 기록을 위임한다.
   */
  func didChangeScreen(to newScreen: AnalyticsScreenData?, from oldScreen: AnalyticsScreenData?)
}
