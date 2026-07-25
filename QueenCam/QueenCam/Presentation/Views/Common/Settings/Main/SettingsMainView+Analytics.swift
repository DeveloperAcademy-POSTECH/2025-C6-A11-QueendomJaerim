//
//  SettingsMainView+Analytics.swift
//  QueenCam
//
//  Created by 임영택 on 7/25/26.
//

extension SettingsMainView {
  func analyticsChanges(
    from previousSettings: SettingsState,
    to newSettings: SettingsState
  ) -> [AnalyticsSettingChange] {
    var changes: [AnalyticsSettingChange] = []

    if previousSettings.saveGuidingOverlayImageOn != newSettings.saveGuidingOverlayImageOn {
      changes.append(
        .makeToggleChange(
          key: .saveGuidingOverlayImage,
          previousValue: previousSettings.saveGuidingOverlayImageOn,
          changedValue: newSettings.saveGuidingOverlayImageOn
        )
      )
    }

    return changes
  }
}
