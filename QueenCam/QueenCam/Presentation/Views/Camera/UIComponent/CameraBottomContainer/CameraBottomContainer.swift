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

    // 캡처시 화면 깜빡임 액션관리
    let shutterActionEffect: () -> Void

    let guidingToolToggle: (_ selectedTool: ActiveTool) -> Void
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
          }
        }
      }
  }

  var body: some View {
    VStack(spacing: 24) {

      guidingTools

      // 썸네일, 촬영 버튼, 따봉 or 셀카
      HStack {
        thumbnailButton

        Spacer()

        captureButton
      }
      .padding(.bottom, 51)
      .padding(.horizontal, 36)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
    .gesture(dragGesture)
  }
}
