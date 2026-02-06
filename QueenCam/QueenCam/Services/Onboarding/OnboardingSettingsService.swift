//
//  OnboardingSettingsService.swift
//  QueenCam
//
//  Created by 임영택 on 1/27/26.
//

import Foundation

final class OnboardingSettingsService: OnboardingSettingsServiceProtocol {
  private let keys = OnboardingSettingKey.allCases

  init() {
    registerDefaultValues()
  }

  var hasShownPhotographerOnboarding: Bool {
    get {
      OnboardingSettingKey.hasShownPhotographerOnboarding.getValue() ?? false
    }
    set {
      OnboardingSettingKey.hasShownPhotographerOnboarding.setValue(newValue)
    }
  }

  var hasShownModelOnboarding: Bool {
    get {
      OnboardingSettingKey.hasShownModelOnboarding.getValue() ?? false
    }
    set {
      OnboardingSettingKey.hasShownModelOnboarding.setValue(newValue)
    }
  }

  func registerDefaultValues() {
    let defaultValues: [String: Any] = keys.reduce([:]) { partialResult, key in
      var copy = partialResult
      copy[key.rawValue] = key.defaultValue
      return copy
    }
    UserDefaults.standard.register(defaults: defaultValues)
  }
}
