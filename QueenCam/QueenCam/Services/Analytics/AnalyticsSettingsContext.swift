//
//  AnalyticsSettingsContext.swift
//  QueenCam
//
//  Created by 임영택 on 7/25/26.
//

import Foundation

/// GA 이벤트와 함께 기록할 현재 앱 설정을 제공하는 객체
final class AnalyticsSettingsContext {
  private let cameraSettingsService: CameraSettingsServiceProtocol

  init(cameraSettingsService: CameraSettingsServiceProtocol) {
    self.cameraSettingsService = cameraSettingsService
  }

  func snapshot() -> AnalyticsSettingsSnapshot {
    AnalyticsSettingsSnapshot(
      livePhotoOn: cameraSettingsService.livePhotoOn,
      gridOn: cameraSettingsService.gridOn,
      flashMode: cameraSettingsService.flashMode,
      saveGuidingOverlayImageOn: cameraSettingsService.saveGuidingOverlayImageOn
    )
  }
}

struct AnalyticsSettingsSnapshot {
  let livePhotoOn: Bool
  let gridOn: Bool
  let flashMode: FlashMode
  let saveGuidingOverlayImageOn: Bool

  var parameters: [String: Any] {
    [
      "settings_live_photo": toggleParameter(livePhotoOn),
      "settings_grid": toggleParameter(gridOn),
      "settings_flash_mode": flashModeParameter,
      "settings_save_guiding_overlay_image": toggleParameter(saveGuidingOverlayImageOn)
    ]
  }

  private func toggleParameter(_ isOn: Bool) -> String {
    isOn ? "on" : "off"
  }

  private var flashModeParameter: String {
    switch flashMode {
    case .off:
      return "off"
    case .on:
      return "on"
    case .auto:
      return "auto"
    }
  }
}
