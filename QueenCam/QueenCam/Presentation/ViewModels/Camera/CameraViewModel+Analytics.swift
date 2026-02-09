//
//  CameraViewModel+Analytics.swift
//  QueenCam
//
//  Created by 임영택 on 11/12/25.
//

import Foundation

extension CameraViewModel {
  func traceShutterPressedEvent() {
    sendEvent(.shutterPressed)
  }

  private func sendEvent(_ event: AnalyticsEvent) {
    AnalyticsService.sendEvent(event)
  }
}
