//
//  MainView.swift
//  QueenCam
//
//  Created by 임영택 on 10/4/25.
//

import SwiftUI

struct MainView: View {
  @State private var router = NavigationRouter()

  @State private var wifiAwareViewModel = WifiAwareViewModel(
    networkService: NetworkService()
  )

  var body: some View {
    Group {
      NavigationStack(path: $router.path) {
        CameraView()
          .navigationDestination(for: Route.self) { route in
            NavigationRouteView(currentRoute: route, wifiAwareViewModel: wifiAwareViewModel)
          }
      }
    }
    .environment(\.router, router)
  }
}
