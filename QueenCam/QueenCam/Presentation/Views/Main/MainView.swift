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

  @State private var wifiAwareViewModel = WifiAwareViewModel(
    networkService: DependencyContainer.defaultContainer.networkService
  )

  @State private var previewModel = PreviewModel(
    previewCaptureService: DependencyContainer.defaultContainer.previewCaptureService,
    networkService: DependencyContainer.defaultContainer.networkService
  )
  
  @State private var isShwoingCurrentConnectionModal: Bool = false

  var body: some View {
    Group {
      NavigationStack(path: $router.path) {
        ZStack {
          CameraView(
            previewModel: previewModel,
            role: wifiAwareViewModel.role,
            networkState: wifiAwareViewModel.networkState,
            connectedDeviceName: wifiAwareViewModel.connectedDevice?.pairingInfo?.pairingName
          ) {
            if wifiAwareViewModel.connections.isEmpty {
              router.push(.establishConnection)
            } else {
              isShwoingCurrentConnectionModal.toggle()
            }
          }
          .navigationDestination(for: Route.self) { route in
            NavigationRouteView(
              currentRoute: route,
              wifiAwareViewModel: wifiAwareViewModel,
              previewModel: previewModel
            )
          }
          
          if isShwoingCurrentConnectionModal {
            Text("CurrentConnectionModal")
          }
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
