//
//  MainView.swift
//  QueenCam
//
//  Created by 임영택 on 10/4/25.
//

import SwiftUI
import WiFiAware

struct MainView: View {
  @State private var router = NavigationRouter()

  @State private var connectionViewModel = ConnectionViewModel(
    networkService: DependencyContainer.defaultContainer.networkService,
    notificationService: DependencyContainer.defaultContainer.notificationService
  )

  @State private var previewModel = PreviewModel(
    previewCaptureService: DependencyContainer.defaultContainer.previewCaptureService,
    networkService: DependencyContainer.defaultContainer.networkService
  )

  @State private var cameraViewModel = CameraViewModel(
    previewCaptureService: DependencyContainer.defaultContainer.previewCaptureService,
    networkService: DependencyContainer.defaultContainer.networkService,
    cameraSettingsService: DependencyContainer.defaultContainer.cameraSettingServcice,
    notificationService: DependencyContainer.defaultContainer.notificationService
  )

  var body: some View {
    Group {
      NavigationStack(path: $router.path) {
        ZStack {
          CameraView(
            cameraViewModel: cameraViewModel,
            previewModel: previewModel,
            connectionViewModel: connectionViewModel
          )
          .navigationDestination(for: Route.self) { route in
            NavigationRouteView(
              currentRoute: route,
              connectionViewModel: connectionViewModel,
              previewModel: previewModel
            )
          }
        }
      }
    }
    #if DEBUG
    .alert(
      "Ping 메시지 도착",
      isPresented: .init(
        get: {
          connectionViewModel.lastPingAt != nil
        },
        set: { present in
          connectionViewModel.lastPingAt = present ? Date() : nil
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
