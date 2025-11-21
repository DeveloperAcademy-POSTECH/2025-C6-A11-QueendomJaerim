//
//  LocaleUtils.swift
//  QueenCam
//
//  Created by 임영택 on 11/21/25.
//

import Foundation

struct LocaleUtils {
  static let appLocales = Bundle.main.preferredLocalizations

  static var currentLocale: Locale {
    if let firstLocale = appLocales.first {
      return Locale.from(identifier: firstLocale)
    }

    return .korean
  }

  enum Locale {
    case korean
    case english
    case unknown

    static func from(identifier: String) -> Locale {
      switch identifier {
      case "ko":
        return .korean
      case "en":
        return .english
      default:
        return .unknown
      }
    }
  }
}
