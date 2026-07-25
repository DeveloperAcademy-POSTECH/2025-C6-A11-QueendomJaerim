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
  case settingsChanged(AnalyticsSettingChange)

  var eventName: String {
    switch self {
    case .sessionStart: return "shooting_session_start"
    case .connectionLost: return "connection_lost"
    case .shutterPressed: return "shutter_pressed"
    case .takeScreenshot: return "take_screenshot"
    case .takeVideoCapture: return "take_video_capture"
    case .settingsChanged: return "settings_changed"
    }
  }

  var eventType: String {
    switch self {
    case .sessionStart: return "connection"
    case .connectionLost: return "connection"
    case .shutterPressed: return "camera"
    case .takeScreenshot: return "device"
    case .takeVideoCapture: return "device"
    case .settingsChanged: return "settings"
    }
  }

  var includesSettingsContext: Bool {
    switch self {
    case .shutterPressed: return true
    default: return false
    }
  }

  var parameters: [String: Any] {
    switch self {
    case .settingsChanged(let change):
      return [
        "changed_key": change.key.rawValue,
        "previous_value": change.previousValue,
        "changed_value": change.changedValue
      ]
    default:
      return [:]
    }
  }
}

enum AnalyticsSettingKey: String {
  case saveGuidingOverlayImage = "save_guiding_overlay_image"
}

struct AnalyticsSettingChange {
  let key: AnalyticsSettingKey
  let previousValue: String
  let changedValue: String

  static func makeToggleChange(
    key: AnalyticsSettingKey,
    previousValue: Bool,
    changedValue: Bool
  ) -> Self {
    AnalyticsSettingChange(
      key: key,
      previousValue: previousValue ? "on" : "off",
      changedValue: changedValue ? "on" : "off"
    )
  }
}
