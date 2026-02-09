//
//  AnalyticsService.swift
//  QueenCam
//
//  Created by 임영택 on 11/12/25.
//

import FirebaseAnalytics

final class AnalyticsService {
  private let logger = QueenLogger(category: "AnalyticsService")

  init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleNotification(_:)),
      name: .QueenCamAnalyticsEventNotification,
      object: nil
    )

    logger.debug("AnalyticsService init")
  }

  @objc private func handleNotification(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
      let event = userInfo["event"] as? AnalyticsEvent
    else {
      logger.warning("received QueenCamAnalyticsEventNotification but payload is invalid type.")
      return
    }

    logEvent(event)
  }

  private func logEvent(_ event: AnalyticsEvent) {
    logger.debug("will send event: \(event.eventName) to FirebaseAnalytics")
    Analytics.logEvent(
      event.eventName,
      parameters: [
        AnalyticsParameterItemName: event.eventName,
        AnalyticsParameterContentType: event.eventType
      ]
    )
  }
}

extension AnalyticsService {
  /// 앱의 어디든 아래 메서드를 이용하면 이벤트를 발행할 수 있다.
  /// 되도록 GA 이벤트 발행을 위해 NotificationCenter.default를 직접 참조하지 않는다.
  static func sendEvent(_ event: AnalyticsEvent) {
    NotificationCenter.default.post(
      name: .QueenCamAnalyticsEventNotification,
      object: nil,
      userInfo: ["event": event]
    )
  }
}
