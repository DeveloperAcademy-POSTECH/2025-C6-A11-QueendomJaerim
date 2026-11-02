//
//  GuidingToolBar.swift
//  QueenCam
//
//  Created by seungchan on 11/2/26.
//

import SwiftUI

extension CameraView {
  struct GuidingToolBar {
    let axis: Axis
    let currentRole: Role?

    let penViewModel: PenViewModel
    let frameViewModel: FrameViewModel

    @Binding var activeTool: ActiveTool?

    /// 눈까리
    @Binding var isRemoteGuideHidden: Bool

    let guidingToolToggle: (_ selectedTool: ActiveTool) -> Void

    // 도구 버튼 토글 애니메이션을 위한 네임스페이스
    @Namespace var toggledToolNamespace
  }
}

extension CameraView.GuidingToolBar {
  var isVertical: Bool {
    axis == .vertical
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

  var disabledByPeer: Bool {
    frameViewModel.isFrameEnabled && frameViewModel.frameOwnerRole != currentRole
  }

  // 세로 모음에서 매직펜만 남으면 Figma처럼 원 모양이 된다.
  private var verticalPadding: CGFloat {
    activeTool == .maginPen ? 12 : 20
  }
}

extension CameraView.GuidingToolBar: View {
  var body: some View {
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
    .padding(
      isVertical
        ? EdgeInsets(top: verticalPadding, leading: 12, bottom: verticalPadding, trailing: 12)
        : EdgeInsets(top: 10, leading: 24, bottom: 12, trailing: 24)
    )
    .glassEffect(.clear, in: .rect(cornerRadius: 99))
  }

  /// 어떤 가이딩 툴도 선택하지 않았을 때 나오는 툴바
  var guidingTools: some View {
    let layout = isVertical
      ? AnyLayout(VStackLayout(spacing: 24))
      : AnyLayout(HStackLayout(alignment: .center, spacing: 32))

    return layout {
      // 프레임
      GuidingButton(
        role: currentRole,
        isActive: isFrameActive,
        isDisabled: isRemoteGuideHidden || disabledByPeer,  // 상대가 소유 중이면 시각적으로도 비활성
        tapAction: {
          if isFrameActive {
            frameViewModel.selectedFrameID = nil
            frameViewModel.requestFrameOwnership(false, currentRole)
          } else {
            frameViewModel.requestFrameOwnership(true, currentRole)
          }
        },
        guidingButtonType: .frame,
        isLabelHidden: isVertical
      )
      .matchedGeometryEffect(id: "frameButton", in: toggledToolNamespace)
      .disabled(disabledByPeer)

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
        guidingButtonType: .pen,
        isLabelHidden: isVertical
      )
      .matchedGeometryEffect(id: "penButton", in: toggledToolNamespace)

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
        guidingButtonType: .magicPen,
        isLabelHidden: isVertical
      )
      .matchedGeometryEffect(id: "magicPenButton", in: toggledToolNamespace)
    }
  }

  /// 프레임을 선택했을 때 나오는 프레임 서브 툴바
  var frameSubToolBar: some View {
    SubToolBar(axis: axis) {
      GuidingButton(
        role: currentRole,
        isActive: isFrameActive,
        isDisabled: isRemoteGuideHidden || disabledByPeer,
        tapAction: {
          // 프레임 소유권 초기화
          frameViewModel.requestFrameOwnership(false, currentRole)  // 상대편 프레임 비활성화 상태 제거(소유자 해제 전파)
        },
        guidingButtonType: .frameChecked,
        isLabelHidden: isVertical
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
          .padding(.trailing, isVertical ? 0 : 8)
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
    SubToolBar(axis: axis) {
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
        guidingButtonType: .penChecked,
        isLabelHidden: isVertical
      )
      .matchedGeometryEffect(id: "penButton", in: toggledToolNamespace)
    } commandButtons: {
      // MARK: - 펜 툴바 Undo / clearAll
      PenToolBar(penViewModel: penViewModel, axis: axis) { action in
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
      guidingButtonType: .magicPenChecked,
      isLabelHidden: isVertical
    )
    .matchedGeometryEffect(id: "magicPenButton", in: toggledToolNamespace)
  }
}

private extension CameraView.GuidingToolBar {
  struct SubToolBar<PrimaryButton: View, CommandButtons: View>: View {
    let axis: Axis
    @ViewBuilder let primaryButton: () -> PrimaryButton
    @ViewBuilder let commandButtons: () -> CommandButtons

    var body: some View {
      if axis == .vertical {
        VStack(spacing: 17) {
          primaryButton()

          Rectangle()
            .fill(.gray900)
            .frame(width: 22, height: 1)

          VStack(spacing: 16) {
            commandButtons()
          }
        }
      } else {
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
}
