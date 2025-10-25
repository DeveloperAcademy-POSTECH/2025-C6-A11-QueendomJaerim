import PhotosUI
import SwiftUI
import WiFiAware

struct CameraView {
  @State private var viewModel = CameraViewModel(cameraSettings: .init())
  @Environment(\.router) private var router
  let previewModel: PreviewModel
  let wifiAwareViewModel: WifiAwareViewModel

  /// 네트워크 상태 모달 노출 여부
  @State private var isShwoingCurrentConnectionModal: Bool = false
  private var isPhotographerMode: Bool {
    wifiAwareViewModel.role == nil || wifiAwareViewModel.role == .photographer
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

  @State private var isPen: Bool = false
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
    viewModel.cameraPostion == .front
  }

  private var flashImage: String {
    switch viewModel.isFlashMode {
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
    viewModel.isCameraPermissionGranted && viewModel.isCameraPermissionGranted
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

        viewModel.setZoom(factor: currentZoomFactor, ramp: false)
      }
      // 핀치를 마쳤을때 한 번 호출될 로직
      .onEnded { _ in
        viewModel.setZoom(factor: currentZoomFactor, ramp: true)
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
                viewModel.switchFlashMode()
              }) {
                Image(systemName: flashImage)
                  .foregroundStyle(viewModel.isFlashMode == .on ? .yellow : .white)
              }

              Button(action: { viewModel.switchLivePhoto() }) {
                Image(systemName: viewModel.isLivePhotoOn ? "livephoto" : "livephoto.slash")
                  .foregroundStyle(viewModel.isLivePhotoOn ? .yellow : .white)
              }

              Spacer()

              Button(action: { viewModel.switchGrid() }) {
                Text(viewModel.isShowGrid ? "그리드 활성화" : "그리드 비활성화")
                  .foregroundStyle(viewModel.isShowGrid ? .yellow : .white)
              }
            }

            NetworkToolbarView(
              networkState: wifiAwareViewModel.networkState,
              connectedDeviceName: wifiAwareViewModel.connectedDeviceName
            ) {
              if wifiAwareViewModel.isConnecting {
                isShwoingCurrentConnectionModal.toggle()
              } else {
                router.push(.establishConnection)
              }
            }
          }
          .padding()

          ZStack {
            if isPhotographerMode {  // 작가
              CameraPreview(session: viewModel.manager.session)
                .aspectRatio(3 / 4, contentMode: .fit)
                .onTapGesture { location in
                  isFocused = true
                  focusLocation = location
                  viewModel.setFocus(point: location)
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
              ReferenceView(referenceViewModel: referenceViewModel, role: .photographer)  //레퍼런스 - 삭제 불가능
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)
              PenDisplayView(penViewModel: penViewModel)
              FrameDisplayView(frameViewModel: frameViewModel)
            } else {  // 모델
              #if DEBUG
              DebugPreviewPlayerView(previewModel: previewModel)
              #else
              PreviewPlayerView(previewModel: previewModel)
              #endif

              ReferenceView(referenceViewModel: referenceViewModel, role: .model)  // 레퍼런스 - 삭제 가능
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(12)

              ZStack(alignment: .topTrailing) {
                Group {
                  if isPen {
                    PenWriteView(penViewModel: penViewModel)
                  } else {
                    PenDisplayView(penViewModel: penViewModel)
                  }

                  if isFrame {
                    FrameControlView(frameViewModel: frameViewModel)
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
                  }
                  CircleButton(
                    systemImage: "camera.metering.center.weighted.average",
                    isActive: isFrame
                  ) {
                    isFrame.toggle()
                    isPen = false
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
            if viewModel.isShowGrid {
              GridView()
                .aspectRatio(3 / 4, contentMode: .fit)
            }

          }

          if !isFront {
            HStack(spacing: 20) {
              if isPhotographerMode {
                ForEach(zoomScaleItemList, id: \.self) { item in
                  Button(action: {
                    viewModel.setZoom(factor: item, ramp: true)
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
              if let image = viewModel.lastImage {
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
              Button(action: { viewModel.capturePhoto() }) {
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
                  await viewModel.switchCamera()
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
          myRole: wifiAwareViewModel.role ?? .model,
          otherDeviceName: wifiAwareViewModel.connectedDeviceName ?? "알 수 없는 기기",
          disconnectButtonDidTap: {
            isShwoingCurrentConnectionModal = false
            wifiAwareViewModel.disconnectButtonDidTap()
          },
          changeRoleButtonDidTap: {
            // TODO: 역할 바꾸기 기능 구현
          }
        )
      }
    }
    .alert(
      "카메라 접근 권한",
      isPresented: $viewModel.isShowSettingAlert,
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
    .task {
      await viewModel.checkPermissions()
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
