//
//  AnalyticsServiceTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 7/25/26.
//

import Testing

@testable import QueenCam

@Suite("AnalyticsService Tests")
struct AnalyticsServiceTests {
  @Test("셔터 이벤트 파라미터에 현재 설정을 포함한다")
  func shutterPressedParametersIncludeCurrentSettings() throws {
    let settingsService = AnalyticsCameraSettingsServiceStub(
      livePhotoOn: true,
      gridOn: false,
      flashMode: .on,
      saveGuidingOverlayImageOn: true
    )
    let context = AnalyticsSettingsContext(cameraSettingsService: settingsService)
    let service = AnalyticsService(
      screenContext: AnalyticsScreenContext(),
      settingsContext: context
    )

    let parameters = service.parameters(for: .shutterPressed)

    #expect(try #require(parameters["settings_live_photo"] as? String) == "on")
    #expect(try #require(parameters["settings_grid"] as? String) == "off")
    #expect(try #require(parameters["settings_flash_mode"] as? String) == "on")
    #expect(try #require(parameters["settings_save_guiding_overlay_image"] as? String) == "on")
  }

  @Test("설정 컨텍스트를 사용하지 않는 이벤트에는 설정 파라미터가 없다")
  func sessionStartParametersExcludeSettings() {
    let settingsService = AnalyticsCameraSettingsServiceStub(
      livePhotoOn: true,
      gridOn: true,
      flashMode: .auto,
      saveGuidingOverlayImageOn: true
    )
    let context = AnalyticsSettingsContext(cameraSettingsService: settingsService)
    let service = AnalyticsService(
      screenContext: AnalyticsScreenContext(),
      settingsContext: context
    )

    let parameters = service.parameters(for: .sessionStart)

    #expect(parameters["settings_live_photo"] == nil)
    #expect(parameters["settings_grid"] == nil)
    #expect(parameters["settings_flash_mode"] == nil)
    #expect(parameters["settings_save_guiding_overlay_image"] == nil)
  }

  @Test("설정 변경 이벤트 파라미터를 최종 페이로드에 포함한다")
  func settingsChangedParametersIncludeChange() {
    let settingsService = AnalyticsCameraSettingsServiceStub(
      livePhotoOn: true,
      gridOn: true,
      flashMode: .auto,
      saveGuidingOverlayImageOn: false
    )
    let service = AnalyticsService(
      screenContext: AnalyticsScreenContext(),
      settingsContext: AnalyticsSettingsContext(cameraSettingsService: settingsService)
    )
    let change = AnalyticsSettingChange.makeToggleChange(
      key: .saveGuidingOverlayImage,
      previousValue: false,
      changedValue: true
    )

    let parameters = service.parameters(for: .settingsChanged(change))

    #expect(parameters["changed_key"] as? String == "save_guiding_overlay_image")
    #expect(parameters["previous_value"] as? String == "off")
    #expect(parameters["changed_value"] as? String == "on")
    #expect(parameters["settings_save_guiding_overlay_image"] == nil)
  }
}

private final class AnalyticsCameraSettingsServiceStub: CameraSettingsServiceProtocol {
  var livePhotoOn: Bool
  var gridOn: Bool
  var flashMode: FlashMode
  var saveGuidingOverlayImageOn: Bool

  init(
    livePhotoOn: Bool,
    gridOn: Bool,
    flashMode: FlashMode,
    saveGuidingOverlayImageOn: Bool
  ) {
    self.livePhotoOn = livePhotoOn
    self.gridOn = gridOn
    self.flashMode = flashMode
    self.saveGuidingOverlayImageOn = saveGuidingOverlayImageOn
  }
}
