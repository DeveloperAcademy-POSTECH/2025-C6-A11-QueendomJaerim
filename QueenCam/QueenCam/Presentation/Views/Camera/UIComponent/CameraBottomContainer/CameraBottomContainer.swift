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

  var isPenActive: Bool {
    activeTool == .pen
  }

  var isMagicPenActive: Bool {
    activeTool == .maginPen
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
    VStack(spacing: 23) {

      Group {
        // 가이드를 선택했을 때 나오는 툴 별 서브 툴바
        if let activeTool {
          switch activeTool {
          case .frame:
            frameSubToolBar
          case .pen:
            penSubToolBar
          case .maginPen:
            magicPenSubToolBar
          }
        } else {
          // 가이드를 아무것도 선택하지 않았을때
          guidingTools
        }
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      .glassEffect(.clear, in: .rect(cornerRadius: 99))

      // 썸네일, 촬영 버튼, 따봉 or 셀카
      HStack {
        thumbnailButton

        Spacer()

        captureButton
      }
      .padding(.bottom, 51)
      .padding(.horizontal, 36)
    }
    .padding(.top, 22)
    .frame(maxWidth: .infinity, maxHeight: isMinimize ? 120 : .infinity)
    .background(.black)
    .gesture(dragGesture)
    .animation(.easeInOut, value: activeTool)
    // 툴 사용중 레퍼런스 확대시 가이드 툴 해제
    .onChange(of: isReferenceLarge) { _, new in
      guard new else { return }
      if activeTool == .pen {
        penViewModel.saveStroke()
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
  }
}

extension CameraView.CameraBottomContainer {
  func minimize(_ activeMinimize: Bool) -> Self {
    var copy = self
    copy.isMinimize = activeMinimize
    return copy
  }
}
