//
//  ConnectionGuideViewModel.swift
//  QueenCam
//
//  Created by 임영택 on 1/27/26.
//

import Foundation

@Observable
final class ConnectionGuideViewModel {
  private let onboardingSettingService: OnboardingSettingServiceProtocol
  
  init(onboardingSettingService: OnboardingSettingServiceProtocol) {
    self.onboardingSettingService = onboardingSettingService
  }
  
  var shouldShowConnectionGuide: Bool {
    !onboardingSettingService.hasShownOnboarding
  }
}

extension ConnectionGuideViewModel {
  
  // MARK: - Intents
  
  func onboardingDidFinish() {
    onboardingSettingService.hasShownOnboarding = true
  }
}
