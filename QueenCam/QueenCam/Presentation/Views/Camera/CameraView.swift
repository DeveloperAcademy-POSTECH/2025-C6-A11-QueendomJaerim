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

  @State private var isShowWifiAwareUnsupportedAlert: Bool = false

  /// 릴리즈 노트를 닫은 뒤 설정 화면으로 이동할지 여부
  @State private var isOpeningSettingsFromReleaseNote: Bool = false
  @State private var navigationRouter = NavigationRouter()

  @State var isReferenceLarge: Bool = false  // 레퍼런스 확대 축소 프로퍼티

  @Environment(\.displayScale) private var displayScale

  let cameraViewModel: CameraViewModel
  let previewModel: PreviewModel
  let connectionViewModel: ConnectionViewModel
  let guideViewModel: ConnectionGuideViewModel
  let referenceViewModel: ReferenceViewModel
  let penViewModel: PenViewModel
  let frameViewModel: FrameViewModel
  let thumbsUpViewModel: ThumbsUpViewModel
  let releaseNoteViewModel: ReleaseNoteViewModel
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

  private var isAvailableWifiAware: Bool {
    WACapabilities.supportedFeatures.contains(.wifiAware)
  }

  // MARK: 화면 틀
  // 프리뷰를 맨 뒤에 깔고, 툴바와 하단 부품은 화면 가장자리에 고정한다.
  // 값의 기준은 Figma 새 4:3 시안이다. 상단 툴바는 위 안전 영역에서 6 아래에 높이 34로 놓이고,
  // 4:3 프리뷰는 툴바 아래 16에서 시작한다. 하단 부품은 아래 안전 영역에서 8 위에 놓인다.
  private static let topToolBarTopInset: CGFloat = 6
  private static let topToolBarHeight: CGFloat = 34
  private static let previewTopSpacing: CGFloat = 16
  private static let bottomContainerBottomInset: CGFloat = 8

  private static var previewTopOffset: CGFloat {
    topToolBarTopInset + topToolBarHeight + previewTopSpacing
  }

  /// 프리뷰 너비. 화면 너비를 채우고, 화면이 넓은 기기(iPad)에서는 안전 영역 높이 안에 들어오도록 줄인다.
  private func previewWidth(in safeAreaSize: CGSize) -> CGFloat {
    min(safeAreaSize.width, (safeAreaSize.height - Self.previewTopOffset) * 3 / 4)
  }

  /// 프리뷰 중앙선의 y 좌표(안전 영역 기준). 4:3 프리뷰 자리의 가운데이며, 비율이 바뀌어도 움직이지 않는다.
  private func previewCenterY(previewWidth: CGFloat) -> CGFloat {
    let height = PhotoAspectRatioGeometry.previewSize(width: previewWidth, ratio: .ratio4x3).height
    return Self.previewTopOffset + height / 2
  }

  private var releaseNoteItemBinding: Binding<ReleaseNote?> {
    Binding(
      get: { releaseNoteViewModel.releaseNoteItem },
      set: { new in
        guard new == nil else { return }
        releaseNoteViewModel.closeReleaseNote()
      }
    )
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

  private var topToolBar: some View {
    HStack {
      // 연결 상태 뷰
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
          if isAvailableWifiAware {
            isShowConnectionView = true
          } else {
            isShowWifiAwareUnsupportedAlert = true
          }
        }
      )
      .alert(
        "연결이 불가능한 기기입니다.",
        isPresented: $isShowWifiAwareUnsupportedAlert,
        actions: {
          Button(role: .cancel) {
          } label: {
            Text("확인했어요")
          }
        },
        message: {
          Text("이 기기는 다른 기기와의 연결이 어려워요. 대신 찍자의 여러 가이드 기능은 이용할 수 있어요.")
        }
      )
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

      Spacer()

      // 버튼 모양은 #497 T11-2에서 Figma 시안대로 바꾼다.
      HStack(spacing: 12) {
        if currentMode == .photographer {
          Button {
            cameraViewModel.switchPhotoAspectRatio()
          } label: {
            Text(verbatim: cameraViewModel.photoAspectRatio.rawValue)
              .typo(.m15)
          }
          .buttonStyle(.glass)
          .accessibilityLabel("사진 비율")
        }

        Button("설정", systemImage: "gearshape") {
          navigationRouter.push(.settings(.main(role: connectionViewModel.role, highlight: nil)))
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.glass)
      }
    }
  }

  var body: some View {
    NavigationStack(path: $navigationRouter.path) {
      GeometryReader { proxy in
        let baseWidth = previewWidth(in: proxy.size)
        let previewSize = PhotoAspectRatioGeometry.previewSize(width: baseWidth, ratio: .ratio4x3)

        ZStack {
          Color.black.ignoresSafeArea()

          // 맨 뒤: 프리뷰. 중앙선에 가운데를 맞춘다.
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
          .padding(DynamicModelUtils.isiPad ? 32 : 0)
          .frame(width: previewSize.width, height: previewSize.height)
          .position(x: proxy.size.width / 2, y: previewCenterY(previewWidth: baseWidth))

          // 하단 부품: 아래 안전 영역에 고정
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
          .minimize(DynamicModelUtils.isiPad)
          .padding(.bottom, Self.bottomContainerBottomInset)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

          // 상단 툴바: 위 안전 영역에 고정
          topToolBar
            .padding(.horizontal, 12)
            .padding(.top, Self.topToolBarTopInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
      }
      .toolbar(.hidden, for: .navigationBar)
      .trackScreen(.camera, Self.self)
      .navigationDestination(for: Route.self) { route in
        switch route {
        case let .settings(settingsRoute):
          SettingsRouteView(currentRoute: settingsRoute, navigationRouter: navigationRouter)
        }
      }
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
      .dynamicTypeSize(.medium)  // FIXME: Dynamic Type 정책 결정 후 수정
    }
    .fullScreenCover(isPresented: $isShowConnectionView) {
      ConnectionView(
        connectionViewModel: connectionViewModel,
        guideViewModel: guideViewModel,
        previewStreamingViewModel: previewModel
      )
        .dynamicTypeSize(.medium) // FIXME: Dynamic Type 정책 결정 후 수정
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
    .fullScreenCover(item: releaseNoteItemBinding) {
      // 릴리즈 노트가 완전히 내려간 뒤에 설정 화면으로 이동한다
      guard isOpeningSettingsFromReleaseNote else { return }
      isOpeningSettingsFromReleaseNote = false
      navigationRouter.push(
        .settings(.main(role: connectionViewModel.role, highlight: .saveGuidingOverlayImage))
      )
    } content: { releaseNote in
      ReleaseNoteView(releaseNote: releaseNote) {
        isOpeningSettingsFromReleaseNote = true
        releaseNoteViewModel.closeReleaseNote()
      } onClose: {
        releaseNoteViewModel.closeReleaseNote()
      }
      .dynamicTypeSize(.medium)  // FIXME: Dynamic Type 정책 결정 후 수정
    }
    .onAppear {
      releaseNoteViewModel.checkReleaseNote()
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
