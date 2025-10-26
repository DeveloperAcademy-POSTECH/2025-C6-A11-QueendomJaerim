//
//  FrameControlView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//

import SwiftUI

/// 전체 프레임을 수정 및 관리 하는 뷰
struct FrameEditorView: View {
  @State var frameViewModel = FrameViewModel()

  var body: some View {
    ZStack {
      GeometryReader { geo in
        ZStack {
          ForEach(frameViewModel.frames) { frame in
            FrameView( frame: frame, containerSize: geo.size, frameViewModel: frameViewModel, isSelected: frameViewModel.isSelected(frame.id)
            )
          }
        }
        .contentShape(Rectangle())
        .onTapGesture {
          frameViewModel.selectFrame(nil)
        }
      }

      // MARK: - 프레임의 Toolbar(추가,삭제)
      VStack {
        Spacer()
        HStack(spacing: 28) {
          Button {
            frameViewModel.addFrame(at: CGPoint(x: 0.3, y: 0.4))
          } label: {
            Image(systemName: "plus")
              .font(.system(size: 25, weight: .semibold))
              .foregroundStyle(.black)
              .frame(width: 60, height: 60)
              .background(.ultraThinMaterial)
              .clipShape(Circle())
              .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
          }
          .disabled(frameViewModel.frames.count >= frameViewModel.maxFrames)

          Button {
            frameViewModel.removeAll()
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 25, weight: .semibold))
              .foregroundStyle(.black)
              .frame(width: 60, height: 60)
              .background(.ultraThinMaterial)
              .clipShape(Circle())
              .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
          }
        }
        .padding(.bottom, 30)
      }
    }
  }
}
