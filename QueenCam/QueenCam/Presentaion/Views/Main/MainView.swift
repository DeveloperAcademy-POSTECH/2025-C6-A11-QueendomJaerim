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
    networkService: DependencyContainer.defaultContainer.networkService
  )
  
  @State private var previewModel = PreviewStreamingViewModel(
    previewCaptureService: DependencyContainer.defaultContainer.previewCaptureService,
    networkService: DependencyContainer.defaultContainer.networkService
  )

  var body: some View {
    Group {
      NavigationStack(path: $router.path) {
        CameraView()
          .navigationDestination(for: Route.self) { route in
            NavigationRouteView(
              currentRoute: route,
              wifiAwareViewModel: wifiAwareViewModel,
              previewModel: previewModel
            )
          }
      }
    }
    #if DEBUG
    .alert(
      "Ping 메시지 도착",
      isPresented: .init(
        get: {
          wifiAwareViewModel.lastPingAt != nil
        },
        set: { present in
          wifiAwareViewModel.lastPingAt = present ? Date() : nil
        }
      )
    ) {
      Button("확인") {
        //
      }
    }
    #endif
    .environment(\.router, router)
  }
}
