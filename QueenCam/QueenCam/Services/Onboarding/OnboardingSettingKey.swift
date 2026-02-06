//
//  OnboardingSettingKey.swift
//  QueenCam
//
//  Created by 임영택 on 2/5/26.
//

import Foundation

enum OnboardingSettingKey: String, CaseIterable {
  case hasShownPhotographerOnboarding
  case hasShownModelOnboarding

  var valueType: Any.Type {
    switch self {
    case .hasShownPhotographerOnboarding:
      return Bool.self
    case .hasShownModelOnboarding:
      return Bool.self
    }
  }

  var defaultValue: Any {
    switch self {
    case .hasShownPhotographerOnboarding:
      return false
    case .hasShownModelOnboarding:
      return false
    }
  }

  func setValue<T>(_ newValue: T) {
    guard T.self == self.valueType else {
      return
    }

    UserDefaults.standard.set(newValue, forKey: self.rawValue)
  }

  func getValue<T>() -> T? {
    guard T.self == self.valueType else {
      return nil
    }

    return UserDefaults.standard.object(forKey: self.rawValue) as? T
  }
}
