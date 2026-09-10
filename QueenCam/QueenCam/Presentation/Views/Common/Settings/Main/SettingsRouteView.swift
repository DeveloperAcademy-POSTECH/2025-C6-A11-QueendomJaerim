//
//  SettingsRouteView.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import SwiftUI

struct SettingsRouteView: View {
  let currentRoute: Route.SettingsRoute
  let navigationRouter: NavigationRouter

  var body: some View {
    switch currentRoute {
    case let .main(role, highlight):
      SettingsMainView(navigationRouter: navigationRouter, role: role, highlight: highlight)
    case .faq:
      FAQView()
    }
  }
}

#Preview {
  SettingsRouteView(
    currentRoute: .main(role: .photographer, highlight: nil),
    navigationRouter: NavigationRouter()
  )
}
