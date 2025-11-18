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
          }
        }
      }
  }

  var body: some View {
    VStack(spacing: 23) {

      Group {
        // 가이드를 선택했을때 그에 따른 상태 표현
        if let activeTool {
          switch activeTool {
          case .frame:
            HStack(spacing: 20) {
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

                  if frameViewModel.isFrameEnabled {
                    isRemoteGuideHidden = false
                  }
                },
                guidingButtonType: .frame
              )

              Rectangle()
                .fill(.gray900)
                .frame(width: 1, height: 39)

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
                  .frame(width: 19, height: 21)
                  .foregroundStyle(frameViewModel.frames.isEmpty ? .gray600 : .offWhite)
              }
              .disabled(frameViewModel.frames.isEmpty)
            }

          case .pen:
            HStack(spacing: 20) {
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

              Rectangle()
                .fill(.gray900)
                .frame(width: 1, height: 39)

              // MARK: - 펜 툴바 Undo / Redo / clearAll
              PenToolBar(penViewModel: penViewModel) { action in
                switch action {
                case .deleteAll:
                  penViewModel.deleteAll()
                  penViewModel.showEraseGuidingLineToast()
                case .undo:
                  penViewModel.undo()
                case .redo:
                  penViewModel.redo()
                }
              }
            }

          case .maginPen:
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
    .frame(maxWidth: .infinity, maxHeight: isMinimize ? 120 : .infinity)
    .background(.black)
    .gesture(dragGesture)
    .animation(.easeInOut, value: activeTool)
  }
}

extension CameraView.CameraBottomContainer {
  func minimize(_ activeMinimize: Bool) -> Self {
    var copy = self
    copy.isMinimize = activeMinimize
    return copy
  }
}
