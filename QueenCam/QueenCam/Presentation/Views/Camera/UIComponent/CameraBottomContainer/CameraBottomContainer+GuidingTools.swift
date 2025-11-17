import SwiftUI

extension CameraView.CameraBottomContainer {
  var guidingTools: some View {
    // 가이딩
    HStack(alignment: .center, spacing: 40) {
      // 프레임
      GuidingButton(
        role: currentRole,
        isActive: isFrameActive,
        isDisabeld: isRemoteGuideHidden,
        tapAction: {
          guard !isRemoteGuideHidden else {
            frameViewModel.showGuidingDisabledToast()
            return
          }

          guidingToolToggle(.frame)
          frameViewModel.setFrame(isFrameActive)

          if isFrameActive && frameViewModel.frames.isEmpty {
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
        isActive: isPenActive,
        isDisabeld: isRemoteGuideHidden,
        tapAction: {
          guard !isRemoteGuideHidden else {
            penViewModel.showGuidingDisabledToast(type: .pen)
            return
          }

          penViewModel.showFirstToolToast(type: .pen)

          guidingToolToggle(.pen)
          if isPenActive {
            isRemoteGuideHidden = false
          }
        },
        guidingButtonType: .pen
      )
      // 매직펜
      GuidingButton(
        role: currentRole,
        isActive: isMagicPenActive,
        isDisabeld: isRemoteGuideHidden,
        tapAction: {
          guard !isRemoteGuideHidden else {
            penViewModel.showGuidingDisabledToast(type: .magicPen)
            return
          }

          penViewModel.showFirstToolToast(type: .magicPen)

          guidingToolToggle(.maginPen)
          if isMagicPenActive {
            isRemoteGuideHidden = false
          }
        },
        guidingButtonType: .magicPen
      )
    }
    .padding(.top, 32)
  }
}
