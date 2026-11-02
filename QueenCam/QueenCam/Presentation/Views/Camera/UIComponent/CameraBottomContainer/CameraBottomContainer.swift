import SwiftUI

extension CameraView {
  struct CameraBottomContainer {
    let currentRole: Role?

    let cameraViewModel: CameraViewModel
    let previewModel: PreviewModel
    let penViewModel: PenViewModel
    let frameViewModel: FrameViewModel
    let referenceViewModel: ReferenceViewModel
    @Bindable var thumbsUpViewModel: ThumbsUpViewModel

    @Binding var activeTool: ActiveTool?

    @Binding var isShowShutterFlash: Bool

    @Binding var isShowCameraSettingTool: Bool

    /// 눈까리
    @Binding var isRemoteGuideHidden: Bool

    @Binding var isShowPhotoPicker: Bool
    @Binding var isReferenceLarge: Bool  // 레퍼런스 확대 축소 프로퍼티

    // 캡처시 화면 깜빡임 액션관리
    let shutterActionEffect: () -> Void

    let isGuidingToolBarHidden: Bool

    let guidingToolToggle: (_ selectedTool: ActiveTool) -> Void
    // 비율이 작은 기기를 위한 모드. true면 뷰 크기 조정
    var isMinimize = false
  }
}

extension CameraView.CameraBottomContainer {
  var currentMode: Role {
    self.currentRole ?? .photographer
  }

  var isFrameActive: Bool {
    activeTool == .frame
  }
}

extension CameraView.CameraBottomContainer: View {
  var dragGesture: some Gesture {
    DragGesture(minimumDistance: 30)
      .onEnded { value in
        guard currentMode == .photographer else { return }
        if value.translation.height < 0 {
          withAnimation {
            self.isShowCameraSettingTool = true
            self.isReferenceLarge = false
          }
        }
      }
  }

  var body: some View {
    VStack(spacing: 18) {

      if !isGuidingToolBarHidden {
        CameraView.GuidingToolBar(
          axis: .horizontal,
          currentRole: currentRole,
          penViewModel: penViewModel,
          frameViewModel: frameViewModel,
          activeTool: $activeTool,
          isRemoteGuideHidden: $isRemoteGuideHidden,
          guidingToolToggle: guidingToolToggle
        )
      }

      // 썸네일, 촬영 버튼, 따봉 or 셀카
      HStack {
        thumbnailButton

        Spacer()

        captureButton
      }
      .padding(.horizontal, 36)
    }
    .frame(maxWidth: isMinimize ? 300 : .infinity, maxHeight: isMinimize ? 120 : nil)
    .contentShape(.rect)
    .gesture(dragGesture)
    .animation(.easeInOut, value: activeTool)
    // 툴 사용중 레퍼런스 확대시 가이드 툴 해제
    .onChange(of: isReferenceLarge) { _, new in
      guard new else { return }
      // FIXME: - 툴 사용 중,레퍼런스 확대 토스트 추가
      if activeTool == .pen {
        penViewModel.saveStroke()
        penViewModel.showToolReferenceLargeToast(type: .pen)
      } else if activeTool == .maginPen {
        penViewModel.showToolReferenceLargeToast(type: .magicPen)
      } else if activeTool == .frame {

      }
      activeTool = nil
    }
    // 확대 상태에서 툴 사용 시도시 레퍼런스 축소
    .onChange(of: activeTool) { _, new in
      guard new != nil else { return }
      withAnimation(.easeInOut(duration: 0.25)) {
        isReferenceLarge = false
      }
    }
    // 프레임의 활성화 여부가 바뀔 때 감지
    .onChange(of: frameViewModel.isFrameEnabled) { _, _ in
      updateFrameToolState()
    }
    // 프레임의 소유주가 바뀔 때도 감지
    .onChange(of: frameViewModel.frameOwnerRole) { _, _ in
      updateFrameToolState()
    }
  }

  /// 프레임 도구 상태 동기화 메서드
  private func updateFrameToolState() {
    let isFrameOwner = (frameViewModel.frameOwnerRole == currentRole)
    if frameViewModel.isFrameEnabled {
      if isFrameOwner {
        if !frameViewModel.frames.isEmpty {
          frameViewModel.selectedFrameID = frameViewModel.frames.first!.id
        }
        if !isFrameActive {
          guidingToolToggle(.frame)
        }
        isRemoteGuideHidden = false
      } else {
        if isFrameActive {
          activeTool = nil  // 강제 종료
        }
        frameViewModel.selectedFrameID = nil
      }
    } else {
      frameViewModel.selectedFrameID = nil
      if isFrameActive {
        activeTool = nil
      }
    }
  }
}

extension CameraView.CameraBottomContainer {
  func minimize(_ activeMinimize: Bool) -> Self {
    var copy = self
    copy.isMinimize = activeMinimize
    return copy
  }
}
