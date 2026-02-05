//
//  ConnectionGuideViewModel.swift
//  QueenCam
//
//  Created by 임영택 on 1/27/26.
//

import Foundation

@Observable
final class ConnectionGuideViewModel {
  private let onboardingSettingService: OnboardingSettingsServiceProtocol

  init(onboardingSettingService: OnboardingSettingsServiceProtocol) {
    self.onboardingSettingService = onboardingSettingService
  }

  func getShouldShowConnectionGuide(currentRole: Role) -> Bool {
    let hasShown: Bool
    switch currentRole {
    case .model:
      hasShown = onboardingSettingService.hasShownModelOnboarding
    case .photographer:
      hasShown = onboardingSettingService.hasShownPhotographerOnboarding
    }

    return !hasShown
  }
}

extension ConnectionGuideViewModel {

  // MARK: - Intents

  func onboardingDidFinish(currentRole: Role) {
    switch currentRole {
    case .model:
      onboardingSettingService.hasShownModelOnboarding = true
    case .photographer:
      onboardingSettingService.hasShownPhotographerOnboarding = true
    }
  }
}
