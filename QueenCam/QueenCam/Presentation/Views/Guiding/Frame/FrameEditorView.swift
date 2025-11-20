//
//  FrameControlView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//

import SwiftUI

/// 전체 프레임을 수정 및 관리 하는 뷰
struct FrameEditorView: View {
  var frameViewModel: FrameViewModel
  var currentRole: Role?

  init(frameViewModel: FrameViewModel, currentRole: Role?) {
    self.frameViewModel = frameViewModel
    self.currentRole = currentRole
    self.frameViewModel.currentRole = currentRole
  }

  var body: some View {
    ZStack {
      GeometryReader { geo in
        ForEach(frameViewModel.frames) { frame in
          FrameView(
            frameViewModel: frameViewModel,
            frame: frame,
            containerSize: geo.size,
            isSelected: frameViewModel.isSelected(frame.id),
            currentRole: currentRole
          )
        }
        .contentShape(Rectangle())
        .onTapGesture {
          frameViewModel.selectFrame(nil)
        }
      }
    }
  }
}
