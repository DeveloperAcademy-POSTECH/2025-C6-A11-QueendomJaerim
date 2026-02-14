//
//  MainView.swift
//  QueenCam
//
//  Created by 임영택 on 10/4/25.
//

import SwiftUI
import WiFiAware

struct MainView: View {
  @State private var connectionViewModel = ConnectionViewModel(
    networkService: DependencyContainer.defaultContainer.networkService,
    notificationService: DependencyContainer.defaultContainer.notificationService
  )
  
  @State private var guideViewModel = ConnectionGuideViewModel(
    onboardingSettingService: DependencyContainer.defaultContainer.onboardingSettingService
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

  @State private var referenceViewModel = ReferenceViewModel()

  @State private var penViewModel = PenViewModel()

  @State private var frameViewModel = FrameViewModel()

  @State private var thumbsUpViewModel = ThumbsUpViewModel()

  @State private var navigationRouter = NavigationRouter()

  var body: some View {
    NavigationStack(path: $navigationRouter.path) {
      CameraView(
        cameraViewModel: cameraViewModel,
        previewModel: previewModel,
        connectionViewModel: connectionViewModel,
        guideViewModel: guideViewModel,
        referenceViewModel: referenceViewModel,
        penViewModel: penViewModel,
        frameViewModel: frameViewModel,
        thumbsUpViewModel: thumbsUpViewModel,
        navigationRouter: navigationRouter
      )
      .dynamicTypeSize(.medium) // FIXME: Dynamic Type 정책 결정 후 수정
      .navigationDestination(for: Route.self) { route in
        switch route {
        case let .settings(settingsRoute):
          SettingsRouteView(currentRoute: settingsRoute, navigationRouter: navigationRouter)
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
  }
}
