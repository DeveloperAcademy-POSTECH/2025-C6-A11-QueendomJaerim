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
    pairedDeviceRegistry: DependencyContainer.defaultContainer.pairedDeviceRegistry
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

  @State private var releaseNoteViewModel = ReleaseNoteViewModel(
    onboardingSettingService: DependencyContainer.defaultContainer.onboardingSettingService
  )

  @ViewBuilder
  var body: some View {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("--ui-testing-select-role-v2") {
      SelectRoleViewV2UITestHost()
    } else {
      cameraView
    }
    #else
    cameraView
    #endif
  }

  private var cameraView: some View {
    CameraView(
      cameraViewModel: cameraViewModel,
      previewModel: previewModel,
      connectionViewModel: connectionViewModel,
      guideViewModel: guideViewModel,
      referenceViewModel: referenceViewModel,
      penViewModel: penViewModel,
      frameViewModel: frameViewModel,
      thumbsUpViewModel: thumbsUpViewModel,
      releaseNoteViewModel: releaseNoteViewModel
    )
    .dynamicTypeSize(.medium) // FIXME: Dynamic Type 정책 결정 후 수정
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

#if DEBUG
private struct SelectRoleViewV2UITestHost: View {
  @State private var isPresented = true
  @State private var selectedRole: Role?
  @State private var result = "presented"

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      Text(result)
        .foregroundStyle(.white)
        .accessibilityIdentifier("select-role-v2.test-result")
    }
    .fullScreenCover(isPresented: $isPresented) {
      SelectRoleViewV2(
        selectedRole: selectedRole,
        didRoleSelect: { role in
          selectedRole = selectedRole == role ? nil : role
        },
        didRoleSubmit: {
          result = "submitted"
          isPresented = false
        }
      )
    }
    .onChange(of: isPresented) { _, isPresented in
      if !isPresented && result != "submitted" {
        result = "dismissed"
      }
    }
  }
}
#endif
