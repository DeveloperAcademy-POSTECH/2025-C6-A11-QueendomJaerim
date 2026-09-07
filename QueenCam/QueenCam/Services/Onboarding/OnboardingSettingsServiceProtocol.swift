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

  /// 마지막으로 노출한 릴리즈 노트의 버전
  var lastShownReleaseNoteVersion: Int { get set }
  func registerDefaultValues()
}
