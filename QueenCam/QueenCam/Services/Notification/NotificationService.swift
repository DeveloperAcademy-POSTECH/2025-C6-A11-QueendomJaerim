//
//  NotificationService.swift
//  QueenCam
//
//  Created by 임영택 on 10/31/25.
//

import Combine
import Foundation

final class NotificationService: NotificationServiceProtocol {
  private var lastNotification: DomainNotification? {
    didSet {
      lastNotificationSubject.send(lastNotification)
    }
  }
  private var lastNotificationSubject = CurrentValueSubject<DomainNotification?, Never>(nil)
  var lastNotificationPublisher: AnyPublisher<DomainNotification?, Never> {
    lastNotificationSubject.eraseToAnyPublisher()
  }

  private var destroyNotificationTimer: Timer?

  func registerNotification(_ notification: DomainNotification) {
    destroyNotificationTimer?.invalidate()
    destroyNotificationTimer = nil

    lastNotification = notification

    if let destroyAfter = notification.showingTime { // nil이면 상시 노출
      destroyNotificationTimer = Timer.scheduledTimer(withTimeInterval: destroyAfter, repeats: false) { [weak self] timer in
        self?.lastNotification = nil
        timer.invalidate()
        self?.destroyNotificationTimer = nil
      }
    }
  }

  func reset() {
    lastNotification = nil
  }
}
