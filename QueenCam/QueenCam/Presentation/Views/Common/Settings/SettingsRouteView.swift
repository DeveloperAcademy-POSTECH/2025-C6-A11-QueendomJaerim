//
//  SettingsRouteView.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import SwiftUI

struct SettingsRouteView: View {
  let currentRoute: Route.SettingsRoute

  var body: some View {
    switch currentRoute {
    case .main:
      SettingsMainView()
    case .faq:
      Text("TODO: FAQ")
    }
  }
}

#Preview {
  SettingsRouteView(currentRoute: .main)
}
