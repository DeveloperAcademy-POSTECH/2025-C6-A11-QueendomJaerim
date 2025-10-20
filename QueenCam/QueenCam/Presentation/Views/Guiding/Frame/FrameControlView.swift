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
      }.background(.clear)
      VStack {
        Spacer()
        HStack {

          Button {
            frameViewModel.addFrame(at: CGPoint(x: 0.3, y: 0.4))
          } label: {
            Image(systemName: "plus")
          }
          .buttonStyle(.borderedProminent)
          .disabled(frameViewModel.allFrames().count >= frameViewModel.maxFrames)

          // MARK: - GuidingToolBar
          Button {
            frameViewModel.removeAll()
          } label: {
            Image(systemName: "xmark.circle")
          }
          .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .padding(.bottom, 24)
      }
    }
  }
}
