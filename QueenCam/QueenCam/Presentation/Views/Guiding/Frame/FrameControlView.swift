//
//  FrameControlView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//

import SwiftUI

struct FrameControlView: View {
  @Bindable var frameViewModel: FrameViewModel

  var body: some View {
    ZStack {
      VStack {
        // MARK: - 프레임 생성 및 이동
        GeometryReader { geo in
          ZStack {
            ForEach(frameViewModel.allFrames()) { frame in
              FrameLayerView(
                frame: frame,
                containerSize: geo.size,
                onDrag: {
                  start,
                  translation in
                  frameViewModel.moveFrame(
                    id: frame.id,
                    start: start,
                    translation: translation,
                    container: geo.size
                  )
                },
                onTap: {
                  frameViewModel.selectFrame(frame.id)
                },
                onDelete: {
                  frameViewModel.remove(frame.id)
                },
                isSelected: frameViewModel.isSelected(frame.id)
              )
            }
          }
          .contentShape(Rectangle())
          .onTapGesture {
            frameViewModel.selectFrame(nil)
          }
        }
        .background(.clear)

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
          .disabled(frameViewModel.allFrames().count >= frameViewModel.maxFrames)

          // MARK: - GuidingToolBar
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
      }
    }
  }
}
