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
        isDisabled: isRemoteGuideHidden || disabledByPeer, // 상대가 소유 중이면 시각적으로도 비활성
        tapAction: {
          guard !isRemoteGuideHidden else {
            frameViewModel.showGuidingDisabledToast()
            return
          }
          // 현재 프레임 소유권 전송 (내가 소유자로 설정)
          frameViewModel.setFrame(true, currentRole)

          // 프레임이 존재하면, isSelected = true
          if !frameViewModel.frames.isEmpty {
            frameViewModel.selectedFrameID = frameViewModel.frames.first!.id
          } // 프레임이 존재 안하면, subToolBar에서 프레임 추가하고 isSelected=true
          guidingToolToggle(.frame)

          if frameViewModel.isFrameEnabled {
            isRemoteGuideHidden = false
          }
        },
        guidingButtonType: .frame
      )
      .disabled(disabledByPeer)

      // 펜
      GuidingButton(
        role: currentRole,
        isActive: isPenActive,
        isDisabled: isRemoteGuideHidden,
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
        isDisabled: isRemoteGuideHidden,
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
  }

  /// 프레임을 선택했을 때 나오는 프레임 서브 툴바
  var frameSubToolBar: some View {
    /// 프레임 버튼 비활성화 조건
    let disabledByPeer = frameViewModel.isFrameEnabled && frameViewModel.frameOwnerRole != currentRole

    return SubToolBar {
      GuidingButton(
        role: currentRole,
        isActive: isFrameActive,
        isDisabled: isRemoteGuideHidden || disabledByPeer,
        tapAction: {
          guard !isRemoteGuideHidden else {
            frameViewModel.showGuidingDisabledToast()
            return
          }
          guidingToolToggle(.frame)
          if frameViewModel.isFrameEnabled {
            isRemoteGuideHidden = false
          }
          // 프레임 소유권 변경 및 초기화: 내가 해제하는 경우에만 owner 제거
          frameViewModel.selectedFrameID = nil // 프레임 선택(isSelected) 초기화 => 제어 모드 종료
          frameViewModel.setFrame(false, nil) // 상대편 프레임 비활성화 상태 제거(소유자 해제 전파)
        },
        guidingButtonType: .frameChecked
      )
    } commandButtons: {
      // 프레임 추가
      Button(action: {
        frameViewModel.setFrame(isFrameActive, currentRole) // 프레임 활성화 상태 + 현재 나의 역할 전송

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

      // 프레임 삭제
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
          guard !isRemoteGuideHidden else {
            penViewModel.showGuidingDisabledToast(type: .pen)
            return
          }

          penViewModel.showFirstToolToast(type: .pen)

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
