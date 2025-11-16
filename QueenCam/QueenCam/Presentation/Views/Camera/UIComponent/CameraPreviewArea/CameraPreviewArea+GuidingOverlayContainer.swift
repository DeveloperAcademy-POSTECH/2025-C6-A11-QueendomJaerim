//
//  CameraPreviewArea+GuidingOverlayContainer.swift
//  QueenCam
//
//  Created by 임영택 on 11/16/25.
//

import SwiftUI

extension CameraView.CameraPreviewArea {
  var guidingOverlayContainer: some View {
    Group {
      if isActiveFrame {
        FrameEditorView(frameViewModel: frameViewModel, currentRole: currentMode)
      }
      if isActivePen || isActiveMagicPen {
        PenWriteView(penViewModel: penViewModel, isPen: isActivePen, isMagicPen: isActiveMagicPen, role: currentMode)
      } else {
        PenDisplayView(penViewModel: penViewModel)
      }
    }
    .opacity(isRemoteGuideHidden ? .zero : 1)
  }
}
