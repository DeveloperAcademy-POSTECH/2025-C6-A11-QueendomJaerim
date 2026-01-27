//
//  OnboardingSettingService.swift
//  QueenCam
//
//  Created by 임영택 on 1/27/26.
//

import Foundation

final class OnboardingSettingService: OnboardingSettingServiceProtocol {
  private let hasShownOnboardingKey = "hasShownOnboarding"

  init() {
    UserDefaults.standard.register(defaults: [
      hasShownOnboardingKey: false
    ])
  }

  var hasShownOnboarding: Bool {
    get {
      UserDefaults.standard.bool(forKey: hasShownOnboardingKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: hasShownOnboardingKey)
    }
  }
}
