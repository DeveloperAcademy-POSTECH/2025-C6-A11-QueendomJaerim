import SwiftUI

extension CameraView.CameraBottomContainer {
  /// 어떤 가이딩 툴도 선택하지 않았을 때 나오는 툴바
  var guidingTools: some View {
    HStack(alignment: .center, spacing: 30) {
      // 프레임
      GuidingButton(
        role: currentRole,
        isActive: isFrameActive,
        isDisabled: isRemoteGuideHidden,
        tapAction: {
          guidingToolToggle(.frame)

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
        isDisabled: isRemoteGuideHidden,
        tapAction: {
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
        isDisabled: isRemoteGuideHidden,
        tapAction: {
          penViewModel.showFirstToolToast(type: .magicPen)
          guidingToolToggle(.maginPen)
          if isMagicPenActive {
            isRemoteGuideHidden = false
          }
        },
        guidingButtonType: .magicPen
      )
    }
  }
  
  /// 프레임을 선택했을 때 나오는 프레임 서브 툴바
  var frameSubToolBar: some View {
    SubToolBar {
      GuidingButton(
        role: currentRole,
        isActive: isFrameActive,
        isDisabled: isRemoteGuideHidden,
        tapAction: {
          guidingToolToggle(.frame)

          if frameViewModel.isFrameEnabled {
            isRemoteGuideHidden = false
          }
        },
        guidingButtonType: .frameChecked
      )
    } commandButtons: {
      Button(action: {
        // FIXME: Edit모드 UI로 수정해야함

        frameViewModel.setFrame(isFrameActive)

        if isFrameActive && frameViewModel.frames.isEmpty {
          frameViewModel.addFrame(at: CGPoint(x: 0.24, y: 0.15))
        }
      }) {
        Image(systemName: "plus")
          .resizable()
          .scaledToFill()
          .font(.system(size: 18, weight: .light))
          .frame(width: 19, height: 21)
          .foregroundStyle(frameViewModel.frames.isEmpty ? .offWhite : .gray600)
          .padding(.trailing, 8)
      }
      .disabled(!frameViewModel.frames.isEmpty)

      Button(action: {
        frameViewModel.deleteAll()
      }) {
        Image(systemName: "trash")
          .resizable()
          .scaledToFill()
          .font(.system(size: 18, weight: .light))
          .frame(width: 19, height: 21)
          .foregroundStyle(frameViewModel.frames.isEmpty ? .gray600 : .offWhite)
      }
      .disabled(frameViewModel.frames.isEmpty)
    }
  }

  /// 펜을 선택했을 때 나오는 펜 서브 툴바
  var penSubToolBar: some View {
    SubToolBar {
      GuidingButton(
        role: currentRole,
        isActive: isPenActive,
        isDisabled: isRemoteGuideHidden,
        tapAction: {
          guidingToolToggle(.pen)
          if isPenActive {
            isRemoteGuideHidden = false
          } else {
            // 펜툴 비활성화 시 세션 strokes들을 persistedStrokes에 저장
            penViewModel.saveStroke()
          }
        },
        guidingButtonType: .penChecked
      )
    } commandButtons: {
      // MARK: - 펜 툴바 Undo / clearAll
      PenToolBar(penViewModel: penViewModel) { action in
        switch action {
        case .deleteAll:
          penViewModel.deleteAll()
          penViewModel.showEraseGuidingLineToast()
        case .undo:
          penViewModel.undo()
        }
      }
    }
  }

  /// 매직펜을 선택했을 때 나오는 매직펜 서브 툴바
  var magicPenSubToolBar: some View {
    GuidingButton(
      role: currentRole,
      isActive: isMagicPenActive,
      isDisabled: isRemoteGuideHidden,
      tapAction: {
        guidingToolToggle(.maginPen)
        if isMagicPenActive {
          isRemoteGuideHidden = false
        }
      },
      guidingButtonType: .magicPenChecked
    )
  }
}

private extension CameraView.CameraBottomContainer {
  struct SubToolBar<PrimaryButton: View, CommandButtons: View>: View {
    @ViewBuilder let primaryButton: () -> PrimaryButton
    @ViewBuilder let commandButtons: () -> CommandButtons

    var body: some View {
      HStack(spacing: 20) {
        primaryButton()

        Rectangle()
          .fill(.gray900)
          .frame(width: 1, height: 39)

        HStack(spacing: 26) {
          commandButtons()
        }
      }
    }
  }
}
