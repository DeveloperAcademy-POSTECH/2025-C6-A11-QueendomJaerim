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
    case let .main(role):
      SettingsMainView(navigationRouter: navigationRouter, role: role)
    case .faq:
      Text("TODO: FAQ")
    }
  }
}

#Preview {
  SettingsRouteView(
    currentRoute: .main(role: .photographer),
    navigationRouter: NavigationRouter()
  )
}
