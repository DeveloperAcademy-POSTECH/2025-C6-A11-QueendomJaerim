//
//  OnboardingSettingsServiceProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 1/27/26.
//

import Foundation

protocol OnboardingSettingsServiceProtocol: AnyObject {
  var hasShownPhotographerOnboarding: Bool { get set }
  var hasShownModelOnboarding: Bool { get set }
  func registerDefaultValues()
}
