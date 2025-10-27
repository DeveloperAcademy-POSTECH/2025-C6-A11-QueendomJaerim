//
//  FrameDisplayView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/20/25.
//

import SwiftUI

/// 프레임의 결과만 보여주는 뷰(읽기 전용)
struct FrameDisplayView: View {
  var frameViewModel: FrameViewModel

  var body: some View {
    GeometryReader { geo in
      ForEach(frameViewModel.frames) { frame in
        let rect = frame.rect
        Rectangle()
          .fill(frame.color)
          .overlay(Rectangle().stroke(frame.color, lineWidth: 2))
          .frame(width: rect.width * geo.size.width, height: rect.height * geo.size.height)
          .position(
            x: (rect.minX + rect.width / 2) * geo.size.width,
            y: (rect.minY + rect.height / 2) * geo.size.height
          )
      }
    }
  }
}
