//
//  AnalyticsEvent.swift
//  QueenCam
//
//  Created by 임영택 on 11/12/25.
//

import Foundation

enum AnalyticsEvent {
  case sessionStart
  case connectionLost
  case shutterPressed

  var eventName: String {
    switch self {
    case .sessionStart: return "shooting_session_start"
    case .connectionLost: return "connection_lost"
    case .shutterPressed: return "shutter_pressed"
    }
  }

  var eventType: String {
    switch self {
    case .sessionStart: return "connection"
    case .connectionLost: return "connection"
    case .shutterPressed: return "camera"
    }
  }
}
