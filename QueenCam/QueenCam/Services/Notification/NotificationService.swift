//
//  NotificationService.swift
//  QueenCam
//
//  Created by 임영택 on 10/31/25.
//

import Combine
import Foundation
import OSLog

final class NotificationService: NotificationServiceProtocol {
  var currentNotification: DomainNotification? {
    if let lastNotification { // 일반 알림이 지정되어있다면 반환
      return lastNotification
    }

    if let baseNotification { // 일반 알림 미지정일 때, 베이스 알림이 지정되어 있다면 반환
      return baseNotification
    }

    return nil // 둘 다 없다면 nil 반환
  }

  // 베이스 알림
  private var baseNotification: DomainNotification? {
    didSet {
      if baseNotification == nil, lastNotification != nil {  // 베이스 알림이 내려갔을 때, lastNotification이 존재하면 nil을 퍼블리시하지 않는다
        return
      }

      lastNotificationSubject.send(baseNotification)
    }
  }

  // 일반 알림
  private var lastNotification: DomainNotification? {
    didSet {
      if lastNotification == nil, let baseNotification {  // 알림이 내려갔을 때, baseNotification이 존재하면 baseNotification를 퍼블리시한다
        lastNotificationSubject.send(baseNotification)
        return
      }

      lastNotificationSubject.send(lastNotification)
    }
  }
  private var lastNotificationSubject = CurrentValueSubject<DomainNotification?, Never>(nil)
  var lastNotificationPublisher: AnyPublisher<DomainNotification?, Never> {
    lastNotificationSubject.eraseToAnyPublisher()
  }

  private var destroyNotificationTimer: Timer?
  
  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "NotificationService")

  func registerNotification(_ notification: DomainNotification) {
    destroyNotificationTimer?.invalidate()
    destroyNotificationTimer = nil

    lastNotification = notification

    if let destroyAfter = notification.showingTime {  // nil이면 상시 노출
      destroyNotificationTimer = Timer.scheduledTimer(withTimeInterval: destroyAfter, repeats: false) { [weak self] timer in
        self?.lastNotification = nil
        timer.invalidate()
        self?.destroyNotificationTimer = nil
      }
    }

    logger.debug("a notification registered: \(String(describing: notification), privacy: .public)")
  }

  func reset() {
    logger.debug("a notification will be removed: \(String(describing: self.lastNotification), privacy: .public)")
    lastNotification = nil
  }

  /// 베이스 알림을 등록한다. showingTime이 nil이 아니어도 무조건 상시노출된다.
  func registerBaseNotification(_ notification: DomainNotification) {
    baseNotification = notification
    
    logger.debug("a base notification registered: \(String(describing: notification), privacy: .public)")
  }

  func resetBaseNotification() {
    logger.debug("a base notification will be removed: \(String(describing: self.baseNotification), privacy: .public)")
    baseNotification = nil
  }
}
