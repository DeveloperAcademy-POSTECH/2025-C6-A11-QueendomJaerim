//
//  CameraPreviewArea+PreviewContent.swift
//  QueenCam
//
//  Created by 임영택 on 11/16/25.
//

import AVKit
import SwiftUI

extension CameraView.CameraPreviewArea {
  /// 프리뷰 컨텐트 영역. 작가(또는 역할 미선택)에게는 자신의 카메라 프리뷰가, 모델에게는 상대방의 카메라 프리뷰가 표시된다
  @ViewBuilder
  var previewContent: some View {
    if currentMode == .photographer {  // 작가 + Default
      CameraPreview(session: cameraViewModel.cameraManager.session)
        .onCameraCaptureEvent { event in
          if event.phase == .ended {
            if cameraViewModel.isCaptureButtonEnabled {
              shutterActionEffect()
              cameraViewModel.capturePhoto()
            }
          }
        }
        .opacity(isShowShutterFlash ? 0 : 1)
        .onTapGesture { location in  // 초점
          isFocused = true
          focusLocation = location
          cameraViewModel.setFocus(point: location)
        }
        .gesture(
          magnificationGesture,
          including: activeTool == .frame ? .none : .all
        )
        .overlay {  // 초점
          if isFocused {
            CameraView.FocusView(position: $focusLocation)
              .onAppear {
                withAnimation {
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.isFocused = false

                  }
                }
              }
          }
        }
    } else {  // 모델
      #if DEBUG
      DebugPreviewPlayerView(previewModel: previewModel)
      #else
      PreviewPlayerView(previewModel: previewModel)
      #endif
    }
  }

  var magnificationGesture: some Gesture {
    MagnifyGesture()
      // 핀치를 하는 동안 계속 호출
      .onChanged { value in
        // 이전 값 대비 상대적 변화량
        let delta = value.magnification / previousMagnificationValue
        // 다음 계산을 위해 현재 배율을 이전 값으로 저장
        previousMagnificationValue = value.magnification

        // 전체 줌 배율 업데이트
        let newZoom = currentZoomFactor * delta
        let clampedZoom = max(0.5, min(newZoom, 2.0))
        currentZoomFactor = clampedZoom

        cameraViewModel.setZoom(factor: currentZoomFactor, ramp: false)
      }
      // 핀치를 마쳤을때 한 번 호출될 로직
      .onEnded { _ in
        cameraViewModel.setZoom(factor: currentZoomFactor, ramp: true)
        previousMagnificationValue = 1.0
      }

  }
}
