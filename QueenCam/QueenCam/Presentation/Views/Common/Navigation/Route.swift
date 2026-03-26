//
//  Route.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import Foundation

enum Route: Hashable {
  case settings(SettingsRoute)

  enum SettingsRoute: Hashable {
    case main(role: Role?)
    case faq
  }
}
