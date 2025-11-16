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
  private var currentMode: Role {
    self.currentRole ?? .photographer
  }

}

extension CameraView.CameraBottomContainer: View {
  var body: some View {

    // 프리뷰 밖 => 이부분을 기준으로 바구니 표현
    VStack(spacing: 24) {
      // 가이딩
      HStack(alignment: .center, spacing: 40) {
        // 프레임
        GuidingButton(
          role: currentRole,
          isActive: isActiveFrame,
          isDisabeld: isRemoteGuideHidden,
          tapAction: {
            guard !isRemoteGuideHidden else {
              frameViewModel.showGuidingDisabledToast()
              return
            }

            isActiveFrame.toggle()
            frameViewModel.setFrame(isActiveFrame)

            if isActiveFrame && frameViewModel.frames.isEmpty {
              frameViewModel.addFrame(at: CGPoint(x: 0.24, y: 0.15))
            }
            if frameViewModel.isFrameEnabled {
              isRemoteGuideHidden = false
            }
          },
          guidingButtonType: .frame
        )
        // 펜
        GuidingButton(
          role: currentRole,
          isActive: isActivePen,
          isDisabeld: isRemoteGuideHidden,
          tapAction: {
            guard !isRemoteGuideHidden else {
              penViewModel.showGuidingDisabledToast(type: .pen)
              return
            }

            penViewModel.showFirstToolToast(type: .pen)

            isActivePen.toggle()
            isActiveMagicPen = false
            if isActivePen {
              isRemoteGuideHidden = false
            }
          },
          guidingButtonType: .pen
        )
        // 매직펜
        GuidingButton(
          role: currentRole,
          isActive: isActiveMagicPen,
          isDisabeld: isRemoteGuideHidden,
          tapAction: {
            guard !isRemoteGuideHidden else {
              penViewModel.showGuidingDisabledToast(type: .magicPen)
              return
            }

            penViewModel.showFirstToolToast(type: .magicPen)

            isActiveMagicPen.toggle()
            isActivePen = false
            if isActiveMagicPen {
              isRemoteGuideHidden = false
            }
          },
          guidingButtonType: .magicPen
        )
      }
      .padding(.top, 32)

      // 썸네일, 촬영 버튼, 따봉 or 셀카
      HStack {
        Button(action: { isShowPhotoPicker.toggle() }) {
          if let image = cameraViewModel.lastImage {
            Image(uiImage: image)
              .resizable()
              .frame(width: 48, height: 48)
              .clipShape(Circle())
          } else {
            if let thumbnailImage = cameraViewModel.thumbnailImage {
              Image(uiImage: thumbnailImage)
                .resizable()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
              EmptyPhotoButton()
            }
          }
        }

        Spacer()

        if currentMode == .photographer {  // 작가 전용 뷰
          Button(action: {
            shutterActionEffect()
            cameraViewModel.capturePhoto()
          }) {
            Circle()
              .fill(.offWhite)
              .stroke(.gray900, lineWidth: 6)
              .frame(width: 80, height: 80)
          }
          .disabled(!cameraViewModel.isCaptureButtonEnabled)

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
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 26, height: 26)
                  .foregroundStyle(.offWhite)
              }
          }
        } else {
          ThumbsUpButton {
            thumbsUpViewModel.userTriggerThumbsUp()
          }
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
          guard currentMode == .photographer else { return }
          if value.translation.height < 0 {
            withAnimation {
              self.isShowCameraSettingTool = true
            }
          }
        }
    )

  }
}
