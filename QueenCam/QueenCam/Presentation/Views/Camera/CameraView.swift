import AVKit
import PhotosUI
import SwiftUI
import WiFiAware

struct CameraView {
  @State private var selectedImage: UIImage?
  @State private var selectedImageID: String?

  @State private var isShowPhotoPicker = false

  // MARK: 현재 활성화된 도구
  @State private var activeTool: ActiveTool?

  @State private var isShowShutterFlash: Bool = false

  @State private var isShowCameraSettingTool: Bool = false

  /// 눈까리
  @State private var isRemoteGuideHidden: Bool = false

  /// 로그 내보내기 시트 노출 여부
  @State private var isShowLogExportingSheet: Bool = false

  // 연결 종료 여부 확인 시트 노출 여부
  @State private var isShowDisconnectAlert = false

  /// 연결 플로우가 진행되는 ConnectionView를 띄울지 여부
  @State private var isShowConnectionView: Bool = false

  @State var isReferenceLarge: Bool = false  // 레퍼런스 확대 축소 프로퍼티

  @Environment(\.displayScale) private var displayScale

  let cameraViewModel: CameraViewModel
  let previewModel: PreviewModel
  let connectionViewModel: ConnectionViewModel
  let referenceViewModel: ReferenceViewModel
  let penViewModel: PenViewModel
  let frameViewModel: FrameViewModel
  let thumbsUpViewModel: ThumbsUpViewModel
}

extension CameraView {
  private var currentMode: Role {
    self.connectionViewModel.role ?? .photographer
  }

  private func openSetting() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }

  private var flashImage: String {
    switch cameraViewModel.isFlashMode {
    case .off:
      return "bolt.slash"
    case .on:
      return "bolt.fill"
    case .auto:
      return "bolt.badge.a"
    @unknown default:
      return "bolt.slash"
    }
  }

  private var liveImage: String {
    cameraViewModel.isLivePhotoOn ? "livephoto" : "livephoto.slash"
  }

  private var isPermissionGranted: Bool {
    cameraViewModel.isCameraPermissionGranted && cameraViewModel.isCameraPermissionGranted
  }

  /// Top Tool Bar
  /// 세션 활성화 여부. False면 툴바에 연결하기 버튼이 노출된다.
  private var isSessionActive: Bool {
    !(connectionViewModel.networkState == nil
      || connectionViewModel.networkState == .host(.stopped)
      || connectionViewModel.networkState == .viewer(.stopped))
  }

  private func flashScreen() {
    isShowShutterFlash = true
    withAnimation(.linear(duration: 0.01)) {
      isShowShutterFlash = false
    }
  }

  // TopToolbar Intent Handlers
  private func changeRoleButtonDidTap() {
    // 가이딩 초기화
    penViewModel.reset()
    frameViewModel.deleteAll()
    referenceViewModel.onReset()
    connectionViewModel.swapRole()
    // 새 역할에 따라 캡쳐를 시작/중단한다
    if let newRole = connectionViewModel.role {
      if newRole == .model {
        previewModel.stopCapture()
      } else if newRole == .photographer {
        previewModel.startCapture()
      }
    }
  }
}

extension CameraView: View {
  private var bottomCameraSettingTool: some View {
    HStack(spacing: 50) {
      CameraSettingButton(
        title: "플래시",
        systemName: flashImage,
        isActive: cameraViewModel.isFlashMode != .off,
        tapAction: { cameraViewModel.switchFlashMode() },
        isToolBar: false
      )

      CameraSettingButton(
        title: "LIVE",
        systemName: liveImage,
        isActive: cameraViewModel.isLivePhotoOn,
        tapAction: { cameraViewModel.switchLivePhoto() },
        isToolBar: false
      )

      CameraSettingButton(
        title: "그리드",
        systemName: "grid",
        isActive: cameraViewModel.isShowGrid,
        tapAction: { cameraViewModel.switchGrid() },
        isToolBar: false
      )
    }
    .frame(width: 377, height: 192)
    .glassEffect(.clear.tint(Color.hex333333), in: .rect(cornerRadius: 59))
  }

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: .zero) {
        // 제일 위 툴바 부분
        TopToolBarView(
          connectedDeviceName: connectionViewModel.connectedDeviceName,
          reconnectingDeviceName: connectionViewModel.reconnectingDeviceName,
          indicatorMenuContent: {
            Button("역할 바꾸기") {
              changeRoleButtonDidTap()
            }

            Button("연결 종료하기", role: .destructive) {
              isShowDisconnectAlert = true
            }
          },
          connectedWithButtonDidTap: {
            isShowConnectionView = true
          }
        )
        .padding()
//        .padding(.top, 12)
        .alert(
          "연결을 종료합니다.",
          isPresented: $isShowDisconnectAlert,
          actions: {
            Button(role: .destructive) {
              connectionViewModel.disconnectButtonDidTap()
            } label: {
              Text("연결 종료하기")
            }

            Button(role: .cancel) {
            } label: {
              Text("취소하기")
            }
          },
          message: {
            Text("친구와 연결을 끊고 촬영을 마칩니다.")
          }
        )

        CameraPreviewArea(
          cameraViewModel: cameraViewModel,
          previewModel: previewModel,
          penViewModel: penViewModel,
          frameViewModel: frameViewModel,
          referenceViewModel: referenceViewModel,
          thumbsUpViewModel: thumbsUpViewModel,
          activeTool: $activeTool,
          isShowShutterFlash: $isShowShutterFlash,
          isShowCameraSettingTool: $isShowCameraSettingTool,
          isRemoteGuideHidden: $isRemoteGuideHidden,
          isReferenceLarge: $isReferenceLarge,
          currentRole: connectionViewModel.role,
          connectionLost: connectionViewModel.connectionLost,
          reconnectCancelButtonDidTap: connectionViewModel.reconnectCancelButtonDidTap,
          shutterActionEffect: flashScreen
        )
        .padding(DynamicScreenUtils.isShortScreen ? 32 : 0)

        CameraBottomContainer(
          currentRole: connectionViewModel.role,
          cameraViewModel: cameraViewModel,
          previewModel: previewModel,
          penViewModel: penViewModel,
          frameViewModel: frameViewModel,
          referenceViewModel: referenceViewModel,
          thumbsUpViewModel: thumbsUpViewModel,
          activeTool: $activeTool,
          isShowShutterFlash: $isShowShutterFlash,
          isShowCameraSettingTool: $isShowCameraSettingTool,
          isRemoteGuideHidden: $isRemoteGuideHidden,
          isShowPhotoPicker: $isShowPhotoPicker,
          isReferenceLarge: $isReferenceLarge,
          shutterActionEffect: flashScreen
        ) { targetTool in
          activeTool = activeTool == targetTool ? nil : targetTool
        }
        .minimize(DynamicScreenUtils.isShortScreen)
      }
      .padding(.top, 5)
    }
    // MARK: 카메라 세팅 툴
    .overlay {
      if isShowCameraSettingTool {
        Color.black.opacity(0.1)
          .ignoresSafeArea()
          .gesture(
            DragGesture(minimumDistance: 30)
              .onEnded { value in
                guard currentMode == .photographer else { return }
                if value.translation.height > 0 {
                  withAnimation {
                    self.isShowCameraSettingTool = false
                  }
                }
              }
          )
          .onTapGesture {
            withAnimation {
              isShowCameraSettingTool = false
            }
          }

        VStack {
          Spacer()

          bottomCameraSettingTool
        }
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom))
      }
    }
    .overlay {  // 권한 관리 뷰
      if !isPermissionGranted {
        ZStack {
          Color.black.opacity(0.7)
            .ignoresSafeArea()

          VStack(spacing: 24) {
            Text("찍자 서비스 이용을 위해\n카메라와 음성 권한을 허용해주세요.")
              .typo(.m15)
              .foregroundStyle(.systemWhite)
              .multilineTextAlignment(.center)

            Button(action: { openSetting() }) {
              Text("설정으로 이동")
                .typo(.m15)
                .foregroundStyle(.systemWhite)
                .frame(width: 147, height: 55)
                .glassEffect(.clear, in: .rect(cornerRadius: 99))
            }
          }
          .padding(.bottom, 80)
        }
      }
    }
    .sheet(isPresented: $isShowPhotoPicker) {
      PhotosPickerView(
        roleForTheme: connectionViewModel.role,
        selectedImageID: $selectedImageID
      ) { image in
        selectedImage = image
        referenceViewModel.onRegister(uiImage: image)
        isShowPhotoPicker = false
      }
      .presentationDetents([.medium, .large])
    }
    .fullScreenCover(isPresented: $isShowConnectionView) {
      ConnectionView(viewModel: connectionViewModel, previewStreamingViewModel: previewModel)
    }
    .onChange(of: connectionViewModel.connections) { oldValue, newValue in
      if !newValue.isEmpty && newValue.count > oldValue.count && connectionViewModel.role == .photographer {
        previewModel.startCapture()
      }
    }
    .overlay {
      // 연결 종료 오버레이
      if connectionViewModel.needReportSessionFinished {
        SessionFinishedOverlayView(reason: LocalizedStringKey("친구가 연결을 종료했어요.\n다시 시작하려면 재연결해주세요.")) {
          connectionViewModel.sessionFinishedOverlayCloseButtonDidTap()
        }
      }

      if let lastStopReason = connectionViewModel.lastStopReason {
        SessionFinishedOverlayView(reason: LocalizedStringKey(lastStopReason)) {
          connectionViewModel.sessionFinishedOverlayCloseButtonDidTap()
        }
      }
    }
    // 연결 종료 시 가이딩 초기화
    .onChange(of: connectionViewModel.networkState) { _, newState in
      guard let newState else { return }
      if newState == .host(.cancelled)
        || newState == .viewer(.cancelled)
        || newState == .host(.lost)
        || newState == .viewer(.lost)
        || newState == .host(.stopped)
        || newState == .viewer(.stopped)
      {
        // 가이딩 초기화
        penViewModel.reset()
        frameViewModel.deleteAll()
        referenceViewModel.onReset()
      }
    }
    // 레퍼런스 삭제 시 PhotoPicker 선택도 초기화
    .onChange(of: referenceViewModel.image) { _, newImage in
      if newImage == nil {
        selectedImage = nil
        selectedImageID = nil
      }
    }
    // 프레임 토글 시 양쪽 모두 (비)활성화
    .onChange(of: frameViewModel.isFrameEnabled) { _, enabled in
      // 상대편 UI 자동 동기화 방지: 소유자일 때만 내 activeTool을 변경
      if enabled {
        if frameViewModel.frameOwnerRole == connectionViewModel.role {
          activeTool = .frame
        }
      } else {
        if frameViewModel.frameOwnerRole == connectionViewModel.role {
          activeTool = nil
        }
      }
    }
    .onChange(of: isShowPhotoPicker) { _, isShow in
      cameraViewModel.managePhotosPickerToast(isShowPhotosPicker: isShow)
    }
    .onChange(of: cameraViewModel.isCapturingLivePhoto) { _, new in
      if new {
        cameraViewModel.showLivePhotoToast()
      }
    }
    .sheet(isPresented: $isShowLogExportingSheet) {
      LogExportingView()
    }
    .task {
      await cameraViewModel.checkPermissions()
      await cameraViewModel.loadThumbnail(scale: displayScale)
    }
    // Life Cycle of the view
    .onAppear {
      UIApplication.shared.isIdleTimerDisabled = true  // 화면 꺼짐 방지
    }
    .onDisappear {
      UIApplication.shared.isIdleTimerDisabled = false
    }
  }
}

extension Color {
  static let hex333333 = Color(red: 0x33 / 255, green: 0x33 / 255, blue: 0x33 / 255)
}
