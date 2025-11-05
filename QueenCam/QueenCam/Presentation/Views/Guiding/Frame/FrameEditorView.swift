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

      // MARK: - 프레임의 Toolbar(추가,삭제)
      //      VStack {
      //        Spacer()
      //        HStack(spacing: 28) {
      //          Button {
      //            frameViewModel.addFrame(at: CGPoint(x: 0.3, y: 0.4))
      //          } label: {
      //            Image(systemName: "plus")
      //              .font(.system(size: 25, weight: .semibold))
      //              .foregroundStyle(.black)
      //              .frame(width: 60, height: 60)
      //              .background(.ultraThinMaterial)
      //              .clipShape(Circle())
      //              .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
      //          }
      //          .disabled(frameViewModel.frames.count >= frameViewModel.maxFrames)
      //
      //          Button {
      //            frameViewModel.deleteAll()
      //          } label: {
      //            Image(systemName: "xmark")
      //              .font(.system(size: 25, weight: .semibold))
      //              .foregroundStyle(.black)
      //              .frame(width: 60, height: 60)
      //              .background(.ultraThinMaterial)
      //              .clipShape(Circle())
      //              .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
      //          }
      //        }
      //        .padding(.bottom, 30)
      //      }
    }
  }
}
