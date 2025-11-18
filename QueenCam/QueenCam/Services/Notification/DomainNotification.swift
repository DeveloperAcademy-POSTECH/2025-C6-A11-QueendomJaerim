//
//  Notification.swift
//  QueenCam
//
//  Created by 임영택 on 10/31/25.
//

import Foundation
import SwiftUI

struct DomainNotification {
  /// 알림 메시지
  let message: LocalizedStringKey

  /// 중요 여부. true이면 노랑색으로 노출한다
  let isImportant: Bool

  /// 생성 시각
  let createdAt: Date

  /// 노출 시간. nil이면 상시 노출한다
  let showingTime: TimeInterval?

  init(message: LocalizedStringKey, isImportant: Bool = false, showingTime: TimeInterval?) {
    self.message = message
    self.isImportant = isImportant
    self.createdAt = Date()
    self.showingTime = showingTime
  }
}

extension DomainNotification: Equatable {}

extension DomainNotification {
  func isType(of type: DomainNotification.DomainNotificationType) -> Bool {
    self.message == type.preset.message
  }
}
