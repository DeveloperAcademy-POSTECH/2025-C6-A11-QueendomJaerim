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

  func logEvent(_ event: AnalyticsEvent) {
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
