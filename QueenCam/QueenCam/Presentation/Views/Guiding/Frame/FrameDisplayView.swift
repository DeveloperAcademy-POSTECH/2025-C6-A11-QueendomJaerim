//
//  FrameDisplayView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/20/25.
//

import SwiftUI

struct FrameDisplayView: View {
  @Bindable var frameViewModel: FrameViewModel
  init(frameViewModel: FrameViewModel) {
    self.frameViewModel = frameViewModel
  }
  var body: some View {
    GeometryReader { geo in
      ForEach(frameViewModel.frames) { frame in
        let rect = frame.rect
        let containerSize = geo.size
        let newWidth = rect.width * containerSize.width
        let newHeight = rect.height * containerSize.height
        let newX = (rect.minX + rect.width / 2) * containerSize.width
        let newY = (rect.minY + rect.height / 2) * containerSize.height

        Rectangle()
          .fill(frame.color)
          .overlay(
            Rectangle().stroke(frame.color, lineWidth: 2)
          )
          .frame(width: newWidth, height: newHeight)
          .position(x: newX, y: newY)

      }
    }
    .background(.clear)
  }
}
