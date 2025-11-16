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

    @Binding var isActiveFrame: Bool
    @Binding var isActivePen: Bool
    @Binding var isActiveMagicPen: Bool

    @Binding var isShowShutterFlash: Bool

    @Binding var isShowCameraSettingTool: Bool

    /// 눈까리
    @Binding var isRemoteGuideHidden: Bool

    @Binding var isShowPhotoPicker: Bool

    // 캡처시 화면 깜빡임 액션관리
    let shutterActionEffect: () -> Void
  }
}

extension CameraView.CameraBottomContainer {
  var currentMode: Role {
    self.currentRole ?? .photographer
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
