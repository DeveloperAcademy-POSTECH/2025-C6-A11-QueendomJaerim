import SwiftUI

extension CameraView.CameraBottomContainer {
  /// 어떤 가이딩 툴도 선택하지 않았을 때 나오는 툴바
  var guidingTools: some View {
    let disabledByPeer = frameViewModel.isFrameEnabled && frameViewModel.frameOwnerRole != currentRole
    return HStack(alignment: .center, spacing: 30) {
      // 프레임
      GuidingButton(
        role: currentRole,
        isActive: isFrameActive,
        isDisabled: !penViewModel.isGuideVisible || disabledByPeer,  // 상대가 소유 중이면 시각적으로도 비활성
        tapAction: {
          if isFrameActive {
            frameViewModel.selectedFrameID = nil
            frameViewModel.requestFrameOwnership(false, currentRole)
          } else{
            frameViewModel.requestFrameOwnership(true, currentRole)
          }
        },
        guidingButtonType: .frame
      )
      .matchedGeometryEffect(id: "frameButton", in: toggledToolNamespace)
      .disabled(disabledByPeer)

      // 펜
      GuidingButton(
        role: currentRole,
        isActive: isPenActive,
        isDisabled: !penViewModel.isGuideVisible,
        tapAction: {
          penViewModel.showFirstToolToast(type: .pen)
          guidingToolToggle(.pen)
          if isPenActive {
            penViewModel.showGuide()
          }
        },
        guidingButtonType: .pen
      )
      .matchedGeometryEffect(id: "penButton", in: toggledToolNamespace)

      // 매직펜
      GuidingButton(
        role: currentRole,
        isActive: isMagicPenActive,
        isDisabled: !penViewModel.isGuideVisible,
        tapAction: {
          penViewModel.showFirstToolToast(type: .magicPen)
          guidingToolToggle(.maginPen)
          if isMagicPenActive {
            penViewModel.showGuide()
          }
        },
        guidingButtonType: .magicPen
      )
      .matchedGeometryEffect(id: "magicPenButton", in: toggledToolNamespace)
    }
  }

  /// 프레임을 선택했을 때 나오는 프레임 서브 툴바
  var frameSubToolBar: some View {
    /// 프레임 버튼 비활성화 조건
    let disabledByPeer = frameViewModel.isFrameEnabled && frameViewModel.frameOwnerRole != currentRole

    return SubToolBar {
      GuidingButton(
        role: currentRole,
        isActive: isFrameActive,
        isDisabled: !penViewModel.isGuideVisible || disabledByPeer,
        tapAction: {
          // 프레임 소유권 초기화
          frameViewModel.requestFrameOwnership(false, currentRole)  // 상대편 프레임 비활성화 상태 제거(소유자 해제 전파)
        },
        guidingButtonType: .frameChecked
      )
      .matchedGeometryEffect(id: "frameButton", in: toggledToolNamespace)
    } commandButtons: {
      // 프레임 추가
      Button(action: {
        if isFrameActive && frameViewModel.frames.isEmpty {
          frameViewModel.addFrame(at: CGPoint(x: 0.24, y: 0.15))
        }
      }) {
        Image(systemName: "plus")
          .font(.system(size: 18, weight: .light))
          .frame(height: 21)
          .foregroundStyle(frameViewModel.frames.isEmpty ? .offWhite : .gray600)
          .padding(.trailing, 8)
      }
      .disabled(!frameViewModel.frames.isEmpty)

      // 프레임 삭제
      Button(action: {
        frameViewModel.deleteAll()
      }) {
        Image(systemName: "trash")
          .font(.system(size: 18, weight: .light))
          .frame(height: 21)
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
        isDisabled: !penViewModel.isGuideVisible,
        tapAction: {
          guidingToolToggle(.pen)
          if isPenActive {
            penViewModel.showGuide()
          } else {
            // 펜툴 비활성화 시 세션 strokes들을 persistedStrokes에 저장
            penViewModel.saveStroke()
          }
        },
        guidingButtonType: .penChecked
      )
      .matchedGeometryEffect(id: "penButton", in: toggledToolNamespace)
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
      isDisabled: !penViewModel.isGuideVisible,
      tapAction: {
        guidingToolToggle(.maginPen)
        if isMagicPenActive {
          penViewModel.showGuide()
        }
      },
      guidingButtonType: .magicPenChecked
    )
    .matchedGeometryEffect(id: "magicPenButton", in: toggledToolNamespace)
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
