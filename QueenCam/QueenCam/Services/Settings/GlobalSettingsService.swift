//
//  GlobalSettingsService.swift
//  QueenCam
//
//  Created by 임영택 on 6/14/26.
//

import Foundation

final class GlobalSettingsService: GlobalSettingsServiceProtocol {
  private let saveGuidingOverlayImageKey = "saveGuidingOverlayImageOn"

  init() {
    UserDefaults.standard.register(defaults: [
      saveGuidingOverlayImageKey: true
    ])
  }

  var saveGuidingOverlayImageOn: Bool {
    get {
      UserDefaults.standard.bool(forKey: saveGuidingOverlayImageKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: saveGuidingOverlayImageKey)
    }
  }
}
