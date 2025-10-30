import PhotosUI
import SwiftUI
import WiFiAware

struct CameraView {
  @Environment(\.router) private var router
  let camerViewModel: CameraViewModel
  let previewModel: PreviewModel
  let connectionViewModel: ConnectionViewModel

  /// 네트워크 상태 모달 노출 여부
  @State private var isShwoingCurrentConnectionModal: Bool = false
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
}

extension CameraView {
  private func openSetting() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }

  private var isFront: Bool {
    camerViewModel.cameraPostion == .front
  }

  private var flashImage: String {
    switch camerViewModel.isFlashMode {
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

  private var isPermissionGranted: Bool {
    camerViewModel.isCameraPermissionGranted && camerViewModel.isCameraPermissionGranted
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

        camerViewModel.setZoom(factor: currentZoomFactor, ramp: false)
      }
      // 핀치를 마쳤을때 한 번 호출될 로직
      .onEnded { _ in
        camerViewModel.setZoom(factor: currentZoomFactor, ramp: true)
        previousMagnificationValue = 1.0

      }
  }

  var body: some View {
    ZStack {
      switch isPermissionGranted {
      case true:
        Color.black.ignoresSafeArea()

        VStack {
          ZStack {
            HStack {
              Button(action: {
                camerViewModel.switchFlashMode()
              }) {
                Image(systemName: flashImage)
                  .foregroundStyle(camerViewModel.isFlashMode == .on ? .yellow : .white)
              }

              Button(action: { camerViewModel.switchLivePhoto() }) {
                Image(systemName: camerViewModel.isLivePhotoOn ? "livephoto" : "livephoto.slash")
                  .foregroundStyle(camerViewModel.isLivePhotoOn ? .yellow : .white)
              }

              Spacer()

              Button(action: { camerViewModel.switchGrid() }) {
                Text(camerViewModel.isShowGrid ? "그리드 활성화" : "그리드 비활성화")
                  .foregroundStyle(camerViewModel.isShowGrid ? .yellow : .white)
              }
            }

            NetworkToolbarView(
              networkState: connectionViewModel.networkState,
              connectedDeviceName: connectionViewModel.connectedDeviceName
            ) {
              if connectionViewModel.isConnecting {
                isShwoingCurrentConnectionModal.toggle()
              } else {
                router.push(.establishConnection)
              }
            }
          }
          .padding()

          ZStack {
            if isPhotographerMode {  // 작가 + Default
              CameraPreview(session: camerViewModel.cameraManager.session)
                .aspectRatio(3 / 4, contentMode: .fit)
                .onTapGesture { location in
                  isFocused = true
                  focusLocation = location
                  camerViewModel.setFocus(point: location)
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
                  if isLarge {
                    Color.black.opacity(0.5)
                      .onTapGesture {
                        isLarge = false
                      }
                  }
                }
            } else {  // 모델
              #if DEBUG
              DebugPreviewPlayerView(previewModel: previewModel)
              #else
              PreviewPlayerView(previewModel: previewModel)
              #endif

              if isLarge {
                Color.black.opacity(0.5)
                  .onTapGesture {
                    isLarge = false
                  }
              }
            }
            if wifiAwareViewModel.role != nil {
              ZStack(alignment: .topTrailing) {
                Group {
                  if isPen || isMagicPen {
                    PenWriteView(penViewModel: penViewModel, isPen: isPen, isMagicPen: isMagicPen, role: wifiAwareViewModel.role)
                  } else {
                    PenDisplayView(penViewModel: penViewModel, role: wifiAwareViewModel.role)
                  }

                  if isFrame {
                    FrameEditorView(frameViewModel: frameViewModel)
                  } else {
                    FrameDisplayView(frameViewModel: frameViewModel)
                  }
                }
                HStack(spacing: 0) {
                  CircleButton(
                    systemImage: "pencil",
                    isActive: isPen
                  ) {
                    isPen.toggle()
                    isFrame = false
                    isMagicPen = false
                  }
                  CircleButton(
                    systemImage: "pointer.arrow.rays",
                    isActive: isMagicPen
                  ) {
                    isMagicPen.toggle()
                    isPen = false
                    isFrame = false
                  }
                  CircleButton(
                    systemImage: "camera.metering.center.weighted.average",
                    isActive: isFrame
                  ) {
                    isFrame.toggle()
                    isPen = false
                    isMagicPen = false

                  }
                }
                .background(
                  Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                )
                .overlay(
                  Capsule()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .frame(width: 120, height: 60)
                .padding(20)
              }
            }
            if camerViewModel.isShowGrid {
              GridView()
                .aspectRatio(3 / 4, contentMode: .fit)
            }
            ReferenceView(referenceViewModel: referenceViewModel, isLarge: $isLarge)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .padding(12)
              .clipped()

          }

          if !isFront {
            HStack(spacing: 20) {
              if isPhotographerMode {
                ForEach(zoomScaleItemList, id: \.self) { item in
                  Button(action: {
                    camerViewModel.setZoom(factor: item, ramp: true)
                    currentZoomFactor = item
                  }) {
                    Text(
                      item == activeZoom
                        ? String(format: "%.1fx", currentZoomFactor) : String(format: "%.1f", item)
                    )
                    .foregroundStyle(item == activeZoom ? .yellow : .white)
                  }
                }

              } else {
                Spacer()
              }
            }
            .padding(.bottom, 32)
          }

          HStack {
            Button(action: { isShowPhotoPicker.toggle() }) {
              if let image = camerViewModel.lastImage {
                Image(uiImage: image)
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 60, height: 60)
                  .clipShape(.rect(cornerRadius: 8))
              } else {
                Rectangle()
                  .fill(.gray.opacity(0.2))
                  .frame(width: 60, height: 60)
                  .clipShape(.rect(cornerRadius: 8))
              }
            }

            Spacer()

            if isPhotographerMode {  // 작가 전용 뷰
              Button(action: { camerViewModel.capturePhoto() }) {
                Circle()
                  .fill(.white)
                  .frame(width: 70, height: 70)
                  .overlay(
                    Circle().stroke(Color.black.opacity(0.8), lineWidth: 2)
                  )
              }

              Spacer()

              Button(action: {
                Task {
                  await camerViewModel.switchCamera()
                }
              }) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 60, height: 60)
              }
            }
          }
        }

      case false:
        Color.black.ignoresSafeArea()

        VStack {
          Text("권한이 거부되었습니다.")
            .foregroundStyle(.white)

          Button(action: { openSetting() }) {
            Text("설정으로 이동하기")
          }
        }
      }

      // MARK: 네트워크 상태 모달
      if isShwoingCurrentConnectionModal {
        NetworkStateModalView(
          myRole: connectionViewModel.role ?? .model,
          otherDeviceName: connectionViewModel.connectedDeviceName ?? "알 수 없는 기기",
          disconnectButtonDidTap: {
            isShwoingCurrentConnectionModal = false
            connectionViewModel.disconnectButtonDidTap()
          },
          changeRoleButtonDidTap: {
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
    .alert(
      "카메라 접근 권한",
      isPresented: .init(
        get: { camerViewModel.isShowSettingAlert },
        set: { camerViewModel.isShowSettingAlert = $0 }
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
      PhotosPickerView(selectedImageID: $selectedImageID) { image in
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
    .task {
      await camerViewModel.checkPermissions()
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
