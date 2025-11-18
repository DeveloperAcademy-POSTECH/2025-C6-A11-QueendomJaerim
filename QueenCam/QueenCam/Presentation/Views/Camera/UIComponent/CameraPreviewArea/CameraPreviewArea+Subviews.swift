//
//  CameraPreviewArea+Subviews.swift
//  QueenCam
//
//  Created by 임영택 on 11/16/25.
//

import SwiftUI

extension CameraView.CameraPreviewArea {
  private var isFrameActive: Bool {
    activeTool == .frame
  }

  private var isPenActive: Bool {
    activeTool == .pen
  }

  private var isMagicPenActive: Bool {
    activeTool == .maginPen
  }

  /// 가이딩 도구들 오버레이
  var guidingLayer: some View {
    Group {
      if isFrameActive {
        FrameEditorView(frameViewModel: frameViewModel, currentRole: currentMode)
      }
      if isPenActive || isMagicPenActive {
        PenWriteView(penViewModel: penViewModel, isPen: isPenActive, isMagicPen: isMagicPenActive, role: currentMode)
      } else {
        PenDisplayView(penViewModel: penViewModel)
      }
    }
    .opacity(isRemoteGuideHidden ? .zero : 1)
  }

  /// 레퍼런스 확대되면 배경에 깔리는 디밍
  @ViewBuilder
  var largeReferenceImageDimmingLayer: some View {
    if isReferenceLarge {  // 레퍼런스 확대 축소
      Color.black.opacity(0.5)
        .onTapGesture {
          withAnimation(.easeInOut(duration: 0.25)) {
            isReferenceLarge = false
          }
        }
    }
  }

  /// 렌즈 배율 조정
  var lensZoomLayer: some View {
    VStack {
      Spacer()
      if !isFront {
        VStack(spacing: .zero) {
          if currentMode == .photographer {
            LensZoomTool(
              zoomScaleItemList: zoomScaleItemList,
              currentZoomFactor: currentZoomFactor,
              activeZoom: activeZoom
            ) { zoom in
              cameraViewModel.setZoom(factor: zoom, ramp: true)
              currentZoomFactor = zoom
            }
          }
        }
        .padding(.vertical, 12)
      }
    }
  }

  /// 카메라 바구니 토글 버튼과 눈까리 버튼
  var toggleButtonsLayer: some View {
    VStack {
      if currentMode == .photographer {
        HStack {
          Spacer()

          // MARK: 카메라 컨트롤 바구니 토글 버튼
          CameraView.ToggleToolboxButton {
            withAnimation {
              isShowCameraSettingTool = true
            }
          }
        }
        .padding(12)
      }

      Spacer()

      if activeTool == nil {
        HStack {
          Spacer()

          // MARK: 눈까리 버튼
          GuidingToggleButton(
            role: currentRole,
            systemName: guideToggleImage,
            isActive: !isRemoteGuideHidden
          ) {
            isRemoteGuideHidden.toggle()
            if isRemoteGuideHidden {
              frameViewModel.setFrame(false)
            } else if !isRemoteGuideHidden && !frameViewModel.frames.isEmpty {
              frameViewModel.setFrame(true)
            }

            cameraViewModel.showGuidingToast(isRemoteGuideHidden: isRemoteGuideHidden)
          }
        }
        .padding(12)
      }
    }
  }
}
