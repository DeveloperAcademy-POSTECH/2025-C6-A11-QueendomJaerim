//
//  AnalyticsEventTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 7/25/26.
//

import Testing

@testable import QueenCam

@Suite("AnalyticsEvent Tests")
struct AnalyticsEventTests {
  @Test("셔터 이벤트만 설정 컨텍스트를 포함한다")
  func onlyShutterPressedIncludesSettingsContext() {
    #expect(AnalyticsEvent.shutterPressed.includesSettingsContext)

    let change = AnalyticsSettingChange(
      key: .saveGuidingOverlayImage,
      previousValue: "off",
      changedValue: "on"
    )
    let eventsWithoutSettingsContext: [AnalyticsEvent] = [
      .sessionStart,
      .connectionLost,
      .takeScreenshot,
      .takeVideoCapture,
      .settingsChanged(change)
    ]

    for event in eventsWithoutSettingsContext {
      #expect(event.includesSettingsContext == false)
    }
  }

  @Test("설정 변경 이벤트가 문자열 변경 페이로드를 제공한다")
  func settingsChangedProvidesStringPayload() {
    let change = AnalyticsSettingChange.makeToggleChange(
      key: .saveGuidingOverlayImage,
      previousValue: false,
      changedValue: true
    )
    let event = AnalyticsEvent.settingsChanged(change)

    #expect(event.eventName == "settings_changed")
    #expect(event.eventType == "settings")
    #expect(event.parameters["changed_key"] as? String == "save_guiding_overlay_image")
    #expect(event.parameters["previous_value"] as? String == "off")
    #expect(event.parameters["changed_value"] as? String == "on")
  }
}
