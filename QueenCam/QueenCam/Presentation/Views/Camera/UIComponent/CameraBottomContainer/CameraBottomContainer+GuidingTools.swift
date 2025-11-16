import SwiftUI

extension CameraView.CameraBottomContainer {
  var guidingTools: some View {
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
  }
}
