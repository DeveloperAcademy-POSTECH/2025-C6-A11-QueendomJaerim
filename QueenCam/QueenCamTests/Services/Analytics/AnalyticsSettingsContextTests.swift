//
//  AnalyticsSettingsContextTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 7/25/26.
//

import Testing

@testable import QueenCam

@Suite("AnalyticsSettingsContext Tests")
struct AnalyticsSettingsContextTests {
  @Test("이벤트 시점의 현재 카메라 설정을 스냅샷한다")
  func snapshotReflectsCurrentCameraSettings() {
    let settingsService = CameraSettingsServiceStub(
      livePhotoOn: false,
      gridOn: true,
      flashMode: .off,
      saveGuidingOverlayImageOn: false
    )
    let context = AnalyticsSettingsContext(cameraSettingsService: settingsService)

    settingsService.livePhotoOn = true
    settingsService.gridOn = false
    settingsService.flashMode = .auto
    settingsService.saveGuidingOverlayImageOn = true

    let snapshot = context.snapshot()

    #expect(snapshot.livePhotoOn == true)
    #expect(snapshot.gridOn == false)
    #expect(snapshot.flashMode == .auto)
    #expect(snapshot.saveGuidingOverlayImageOn == true)
    #expect(snapshot.parameters["settings_live_photo"] as? String == "on")
    #expect(snapshot.parameters["settings_grid"] as? String == "off")
    #expect(snapshot.parameters["settings_flash_mode"] as? String == "auto")
    #expect(snapshot.parameters["settings_save_guiding_overlay_image"] as? String == "on")
  }
}

private final class CameraSettingsServiceStub: CameraSettingsServiceProtocol {
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
