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
    notificationService: DependencyContainer.defaultContainer.notificationService,
    waPairedDevicesRepository: DependencyContainer.defaultContainer.waPairedDevicesRepository
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

  var body: some View {
    CameraView(
      cameraViewModel: cameraViewModel,
      previewModel: previewModel,
      connectionViewModel: connectionViewModel,
      referenceViewModel: referenceViewModel,
      penViewModel: penViewModel,
      frameViewModel: frameViewModel,
      thumbsUpViewModel: thumbsUpViewModel
    )
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
