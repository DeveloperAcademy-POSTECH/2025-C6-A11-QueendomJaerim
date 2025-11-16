//
//  NetworkService+Analytics.swift
//  QueenCam
//
//  Created by 임영택 on 11/12/25.
//

import Foundation

extension NetworkService {
  // Analytics

  func traceConnectionLostEvent() {
    sendEvent(.connectionLost)
  }

  func traceSessionStartEvent() {
    sendEvent(.sessionStart)
  }

  private func sendEvent(_ event: AnalyticsEvent) {
    NotificationCenter.default.post(
      name: .QueenCamAnalyticsEventNotification,
      object: nil,
      userInfo: ["event": event]
    )
  }
}
