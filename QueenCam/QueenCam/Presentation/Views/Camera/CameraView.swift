import PhotosUI
import SwiftUI
import WiFiAware

struct CameraView {
  @Environment(\.router) private var router
  let cameraViewModel: CameraViewModel
  let previewModel: PreviewModel
  let connectionViewModel: ConnectionViewModel

  /// 네트워크 상태 모달 노출 여부
  @State private var isShowingCurrentConnectionModal: Bool = false
  private var isPhotographerMode: Bool {
    connectionViewModel.role == nil || connectionViewModel.role == .photographer
  }

  @State private var selectedImage: UIImage?
  @State private var selectedImageID: String?

  @State private var zoomScaleItemList: [CGFloat] = [0.5, 1, 2]

  // 현재 적용된 줌 배율 (카메라와 UI 상태 동기화용)
  @State private var currentZoomFactor: CGFloat = 1.0
  // 현재 하나의 핀치 동작 내에서 이전 배율 값을 임시 저장 (변화량을 계산하기 위해)
  @State private var previousMagnificationValue: CGFloat = 1.0

  @State private var isFocused = false
  @State private var focusLocation: CGPoint = .zero

  @State private var isShowPhotoPicker = false
  @State private var referenceViewModel = ReferenceViewModel()
  @State private var isLarge: Bool = false

  @State private var isPen: Bool = false
  @State private var isMagicPen: Bool = false
  @State private var penViewModel = PenViewModel()

  @State private var frameViewModel = FrameViewModel()
  @State private var isFrame: Bool = false

  @State private var isRemoteGuideHidden: Bool = false
  @State private var isShowCameraSettingTool: Bool = false
}

extension CameraView {
  private func openSetting() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }

  private var isFront: Bool {
    cameraViewModel.cameraPostion == .front
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

  private var guideToggleImage: String {
    isRemoteGuideHidden ? "eye.slash" : "eye"
  }

  private var activeZoom: CGFloat {
    switch currentZoomFactor {
    case ..<0.95:
      return 0.5
    case ..<1.95:
      return 1
    default:
      return 2
    }
  }
}

/// Top Tool Bar
extension CameraView {
  /// 세션 활성화 여부. False면 툴바에 연결하기 버튼이 노출된다.
  var isSessionActive: Bool {
    !(connectionViewModel.networkState == nil
      || connectionViewModel.networkState == .host(.stopped)
      || connectionViewModel.networkState == .viewer(.stopped))
  }
}

extension CameraView: View {
  var magnificationGesture: some Gesture {
    MagnifyGesture()
      // 핀치를 하는 동안 계속 호출
      .onChanged { value in
        // 이전 값 대비 상대적 변화량
        let delta = value.magnification / previousMagnificationValue
        // 다음 계산을 위해 현재 배율을 이전 값으로 저장
        previousMagnificationValue = value.magnification

        // 전체 줌 배율 업데이트
        let newZoom = currentZoomFactor * delta
        let clampedZoom = max(0.5, min(newZoom, 2.0))
        currentZoomFactor = clampedZoom

        cameraViewModel.setZoom(factor: currentZoomFactor, ramp: false)
      }
      // 핀치를 마쳤을때 한 번 호출될 로직
      .onEnded { _ in
        cameraViewModel.setZoom(factor: currentZoomFactor, ramp: true)
        previousMagnificationValue = 1.0

      }
  }

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
  
  private var toolBarCameraSettingTool: some View {
    ControlGroup {
      CameraSettingButton(
        title: "플래시",
        systemName: flashImage,
        isActive: cameraViewModel.isFlashMode != .off,
        tapAction: { cameraViewModel.switchFlashMode() },
        isToolBar: true
      )

      CameraSettingButton(
        title: "LIVE",
        systemName: liveImage,
        isActive: cameraViewModel.isLivePhotoOn,
        tapAction: { cameraViewModel.switchLivePhoto() },
        isToolBar: true
      )

      CameraSettingButton(
        title: "그리드",
        systemName: "grid",
        isActive: cameraViewModel.isShowGrid,
        tapAction: { cameraViewModel.switchGrid() },
        isToolBar: true
      )
    }
  }

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      switch isPermissionGranted {
      case true:
        VStack(spacing: .zero) {
          /// 제일 위 툴바 부분
          TopToolBarView(
            isConnected: isSessionActive,
            connectedDeviceName: connectionViewModel.connectedDeviceName,
            menuContent: {
              toolBarCameraSettingTool

              Button("기능 1") {}
              Button("기능 2") {}
              Button("기능 3") {}

              Divider()

              Button("신고하기", systemImage: "exclamationmark.triangle") {}
            },
            connectedWithButtonDidTap: {
              if connectionViewModel.isConnecting {
                isShowingCurrentConnectionModal.toggle()
              } else {
                router.push(.establishConnection)
              }
            }
          )
          .padding()

          ZStack {
            if isPhotographerMode {  // 작가 + Default
              CameraPreview(session: cameraViewModel.cameraManager.session)
                .onTapGesture { location in
                  isFocused = true
                  focusLocation = location
                  cameraViewModel.setFocus(point: location)
                }
                .gesture(magnificationGesture)

                .overlay {
                  if isFocused {
                    FocusView(position: $focusLocation)
                      .onAppear {
                        withAnimation {
                          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            self.isFocused = false

                          }
                        }
                      }
                  }
                }
            } else {  // 모델
              #if DEBUG
              DebugPreviewPlayerView(previewModel: previewModel)
              #else
              PreviewPlayerView(previewModel: previewModel)
              #endif
            }

            if isLarge {
              Color.black.opacity(0.5)
                .onTapGesture {
                  isLarge = false
                }
            }

            if cameraViewModel.isShowGrid {
              GridView()
            }

            ReferenceView(referenceViewModel: referenceViewModel, isLarge: $isLarge)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .padding(12)
              .clipped()

            Group {
              if isFrame {
                FrameEditorView(frameViewModel: frameViewModel)
              }
              if isPen || isMagicPen {
                PenWriteView(penViewModel: penViewModel, isPen: isPen, isMagicPen: isMagicPen, role: connectionViewModel.role)
              } else {
                PenDisplayView(penViewModel: penViewModel, role: connectionViewModel.role)
              }
            }
            .opacity(isRemoteGuideHidden ? .zero : 1)

            VStack {
              Spacer()
              if !isFront {
                VStack(spacing: .zero) {
                  if isPhotographerMode {
                    LensZoomTool(
                      zoomScaleItemList: zoomScaleItemList,
                      currentZoomFactor: currentZoomFactor,
                      activeZoom: activeZoom,
                      onZoomChange: { zoom in
                        cameraViewModel.setZoom(factor: zoom, ramp: true)
                        currentZoomFactor = zoom
                      }
                    )
                  }
                }
                .padding(.vertical, 12)
              }
            }

            VStack {
              Spacer()
              HStack {
                Spacer()
                GuidingToggleButton(
                  role: connectionViewModel.role,
                  systemName: guideToggleImage,
                  isActive: !isRemoteGuideHidden,
                  tapAction: {
                    print("dd")
                    isRemoteGuideHidden.toggle()
                    if isRemoteGuideHidden {
                      isPen = false
                      isMagicPen = false
                      isFrame = false
                    }
                  }
                )
              }
              .padding(12)
            }
          }
          .aspectRatio(3 / 4, contentMode: .fill)
          .clipShape(.rect(cornerRadius: 5))
          .overlay {
            RoundedRectangle(cornerRadius: 5)
              .stroke(.gray, lineWidth: 1)
          }
          .padding(.horizontal, 16)
          .overlay(alignment: .center) {
            StateToastContainer()
              .padding(.top, 16)
          }

          // 프리뷰 밖 => 이부분을 기준으로 바구니 표현
          VStack(spacing: 24) {
            HStack(alignment: .center, spacing: 40) {
              //프레임
              GuidingButton(
                role: connectionViewModel.role,
                isActive: isFrame,
                tapAction: {
                  isFrame.toggle()
                  if isFrame {
                    isRemoteGuideHidden = false
                  }
                },
                guidingButtonType: .frame
              )
              // 펜
              GuidingButton(
                role: connectionViewModel.role,
                isActive: isPen,
                tapAction: {
                  isPen.toggle()
                  isMagicPen = false
                  if isPen {
                    isRemoteGuideHidden = false
                  }
                },
                guidingButtonType: .pen
              )
              // 매직펜
              GuidingButton(
                role: connectionViewModel.role,
                isActive: isMagicPen,
                tapAction: {
                  isMagicPen.toggle()
                  isPen = false
                  if isMagicPen {
                    isRemoteGuideHidden = false
                  }
                },
                guidingButtonType: .magicPen
              )
            }
            .padding(.top, 32)

            HStack {
              Button(action: { isShowPhotoPicker.toggle() }) {
                if let image = cameraViewModel.lastImage {
                  Image(uiImage: image)
                    .resizable()
                    .clipShape(Circle())
                    .frame(width: 48, height: 48)
                } else {
                  EmptyPhotoButton()
                }
              }

              Spacer()

              if isPhotographerMode {  // 작가 전용 뷰
                Button(action: { cameraViewModel.capturePhoto() }) {
                  Circle()
                    .fill(.offWhite)
                    .stroke(.gray900, lineWidth: 6)
                    .frame(width: 80, height: 80)
                }

                Spacer()

                Button(action: {
                  Task {
                    await cameraViewModel.switchCamera()
                  }
                }) {

                  Circle()
                    .fill(.gray900)
                    .frame(width: 48, height: 48)
                    .overlay {
                      Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.system(size: 22))
                        .foregroundStyle(.offWhite)
                    }
                }
              } else {
                BoomupButton(tapAction: {})
              }
            }
            .padding(.bottom, 51)
            .padding(.horizontal, 36)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(.black)
          .gesture(
            DragGesture(minimumDistance: 30)
              .onEnded { value in
                guard isPhotographerMode else { return }
                withAnimation {
                  self.isShowCameraSettingTool = true
                }
              }
          )
        }

      case false:
        VStack {
          Text("권한이 거부되었습니다.")
            .foregroundStyle(.white)

          Button(action: { openSetting() }) {
            Text("설정으로 이동하기")
          }
        }
      }

      // MARK: 네트워크 상태 모달
      if isShowingCurrentConnectionModal {
        NetworkStateModalView(
          myRole: connectionViewModel.role ?? .model,
          otherDeviceName: connectionViewModel.connectedDeviceName ?? "알 수 없는 기기",
          disconnectButtonDidTap: {
            isShowingCurrentConnectionModal = false
            connectionViewModel.disconnectButtonDidTap()
          },
          changeRoleButtonDidTap: {
            // 가이딩 초기화
            penViewModel.reset()
            frameViewModel.deleteAll()
            referenceViewModel.onDelete()
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
        )
      }
    }
    // MARK: 카메라 세팅 툴
    .overlay {
      if isShowCameraSettingTool {
        Color.black.opacity(0.1)
          .ignoresSafeArea()
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
    .alert(
      "카메라 접근 권한",
      isPresented: .init(
        get: { cameraViewModel.isShowSettingAlert },
        set: { cameraViewModel.isShowSettingAlert = $0 }
      ),
      actions: {
        Button(role: .cancel, action: {}) {
          Text("취소")
        }

        Button(action: { openSetting() }) {
          Text("설정으로 이동")
        }
      },
      message: {
        Text("설정에서 카메라 접근 권한을 허용해주세요.")
      }
    )
    .sheet(isPresented: $isShowPhotoPicker) {
      PhotosPickerView(roleForTheme: connectionViewModel.role, selectedImageID: $selectedImageID) { image in
        selectedImage = image
        referenceViewModel.onRegister(uiImage: image)
        isShowPhotoPicker = false
      }
      .presentationDetents([.medium, .large])
    }
    .overlay {
      if connectionViewModel.connectionLost {
        ReconnectingOverlayView {
          connectionViewModel.reconnectCancelButtonDidTap()
        }
      }
    }
    .onChange(of: connectionViewModel.connections) { _, newValue in
      if !newValue.isEmpty && connectionViewModel.role == .photographer {
        previewModel.startCapture()
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
        referenceViewModel.onDelete()
      }
    }
    .task {
      await cameraViewModel.checkPermissions()
    }
  }
}

struct FocusView: View {
  @Binding var position: CGPoint

  var body: some View {
    Rectangle()
      .frame(width: 70, height: 70)
      .foregroundStyle(.clear)
      .border(Color.yellow, width: 1.5)
      .position(x: position.x, y: position.y)
  }
}

extension Color {
  static let hex333333 = Color(red: 0x33 / 255, green: 0x33 / 255, blue: 0x33 / 255)
}
