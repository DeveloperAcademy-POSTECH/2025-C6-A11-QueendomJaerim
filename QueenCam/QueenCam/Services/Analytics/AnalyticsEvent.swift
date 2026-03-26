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
  case takeScreenshot
  case takeVideoCapture
  /// 프레임 활성화 횟수
  case frameSelected(role: String)
  /// 펜의 활성화 횟수
  case penSelected(role: String)
  /// 매직펜의 활성화 횟수
  case magicPenSelected(role: String)

  var eventName: String {
    switch self {
    case .sessionStart: return "shooting_session_start"
    case .connectionLost: return "connection_lost"
    case .shutterPressed: return "shutter_pressed"
    case .takeScreenshot: return "take_screenshot"
    case .takeVideoCapture: return "take_video_capture"
    case .frameSelected: return "guiding_frame_selected"
    case .penSelected: return "guiding_pen_selected"
    case .magicPenSelected: return "guiding_magicpen_selected"
    }
  }
  
  var eventType: String {
    switch self {
    case .sessionStart: return "connection"
    case .connectionLost: return "connection"
    case .shutterPressed: return "camera"
    case .takeScreenshot: return "device"
    case .takeVideoCapture: return "device"
    case .frameSelected: return "guiding"
    case .penSelected: return "guiding"
    case .magicPenSelected: return "guiding"
    }
  }
}
