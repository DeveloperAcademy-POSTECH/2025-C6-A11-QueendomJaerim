import AVKit
import PhotosUI
import SwiftUI
import WiFiAware

extension CameraView {
  struct CameraPreviewArea {
    @State private var isFocused = false
    @State private var focusLocation: CGPoint = .zero
    @State private var isReferenceLarge: Bool = false  // 레퍼런스 확대 축소 프로퍼티
    @State private var zoomScaleItemList: [CGFloat] = [0.5, 1, 2]
    // 현재 적용된 줌 배율 (카메라와 UI 상태 동기화용)
    @State private var currentZoomFactor: CGFloat = 1.0
    // 현재 하나의 핀치 동작 내에서 이전 배율 값을 임시 저장 (변화량을 계산하기 위해)
    @State private var previousMagnificationValue: CGFloat = 1.0

    let cameraViewModel: CameraViewModel
    let previewModel: PreviewModel
    let penViewModel: PenViewModel
    let frameViewModel: FrameViewModel
    let referenceViewModel: ReferenceViewModel
    @Bindable var thumbsUpViewModel: ThumbsUpViewModel

    @Binding var isActiveFrame: Bool
    @Binding var isActivePen: Bool
    @Binding var isActiveMagicPen: Bool

    @Binding var isShowShutterFlash: Bool

    @Binding var isShowCameraSettingTool: Bool

    /// 눈까리
    @Binding var isRemoteGuideHidden: Bool

    // connectionViewModel -> 프로퍼티 변환
    let currentRole: Role?
    let connectionLost: Bool
    let reconnectCancelButtonDidTap: () -> Void

    // 캡처시 화면 깜빡임 액션관리
    let shutterActionEffect: () -> Void
  }
}

extension CameraView.CameraPreviewArea {
  private var currentMode: Role {
    self.currentRole ?? .photographer
  }

  private var isFront: Bool {
    cameraViewModel.cameraPostion == .front
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

  private var guideToggleImage: String {
    isRemoteGuideHidden ? "eye.slash" : "eye"
  }
}

extension CameraView.CameraPreviewArea: View {
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

  var body: some View {
    // 카메라 프리뷰
    ZStack {

      if currentMode == .photographer {  // 작가 + Default
        CameraPreview(session: cameraViewModel.cameraManager.session)
          .onCameraCaptureEvent { event in
            if event.phase == .ended {
              if cameraViewModel.isCaptureButtonEnabled {
                shutterActionEffect()
                cameraViewModel.capturePhoto()
              }
            }
          }
          .opacity(isShowShutterFlash ? 0 : 1)
          .onTapGesture { location in  // 초점
            isFocused = true
            focusLocation = location
            cameraViewModel.setFocus(point: location)
          }
          .gesture(magnificationGesture)

          .overlay {  // 초점
            if isFocused {
              CameraView.FocusView(position: $focusLocation)
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

      if isReferenceLarge {  // 레퍼런스 확대 축소
        Color.black.opacity(0.5)
          .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
              isReferenceLarge = false
            }
          }
      }

      if cameraViewModel.isShowGrid {
        GridView()
      }

      Group {

        if isActiveFrame {
          FrameEditorView(frameViewModel: frameViewModel, currentRole: currentMode)
        }
        if isActivePen || isActiveMagicPen {
          PenWriteView(penViewModel: penViewModel, isPen: isActivePen, isMagicPen: isActiveMagicPen, role: currentMode)
        } else {
          PenDisplayView(penViewModel: penViewModel)
        }
      }
      .opacity(isRemoteGuideHidden ? .zero : 1)

      VStack {  //  렌즈 배율
        Spacer()
        if !isFront {
          VStack(spacing: .zero) {
            if currentMode == .photographer {
              LensZoomTool(
                zoomScaleItemList: zoomScaleItemList,
                currentZoomFactor: currentZoomFactor,
                activeZoom: activeZoom
              ) { zoom in
                cameraViewModel.setZoom(factor: zoom, ramp: true)
                currentZoomFactor = zoom
              }
            }
          }
          .padding(.vertical, 12)
        }
      }

      VStack {
        if currentMode == .photographer {
          HStack {
            Spacer()
            CameraView.ToggleToolboxButton {
              withAnimation {
                isShowCameraSettingTool = true
              }
            }
          }
          .padding(12)
        }

        Spacer()

        HStack {
          Spacer()
          GuidingToggleButton(
            role: currentRole,
            systemName: guideToggleImage,
            isActive: !isRemoteGuideHidden
          ) {
            isRemoteGuideHidden.toggle()
            if isRemoteGuideHidden {
              frameViewModel.setFrame(false)
            } else if !isRemoteGuideHidden && !frameViewModel.frames.isEmpty {
              frameViewModel.setFrame(true)
            }

            cameraViewModel.showGuidingToast(isRemoteGuideHidden: isRemoteGuideHidden)
          }
        }
        .padding(12)
      }

      ReferenceView(referenceViewModel: referenceViewModel, isLarge: $isReferenceLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .clipped()

      // 연결 유실시 재연결 뷰
      if connectionLost {
        ReconnectingView(didCancelButtonTap: reconnectCancelButtonDidTap)
      }
    }
    .aspectRatio(3 / 4, contentMode: .fill)
    .clipped()
    .clipShape(.rect(cornerRadius: 5))
    .overlay {
      RoundedRectangle(cornerRadius: 5)
        .inset(by: 0.5)
        .stroke(Color.gray900, lineWidth: 1)
    }
    .padding(.horizontal, 16)
    .overlay(alignment: .center) {
      if !connectionLost {
        StateToastContainer()
          .padding(.top, 16)
      }
    }
    // 따봉 버튼 눌렀을 때 나올 뷰 => 둘다 표현해야 되기 때문에 따로 분기 처리 X
    .overlay(alignment: .bottom) {
      ThumbsUpView(trigger: $thumbsUpViewModel.animationTriger)
        .opacity(thumbsUpViewModel.isShowInitialView ? 1 : .zero)
    }
  }
}
