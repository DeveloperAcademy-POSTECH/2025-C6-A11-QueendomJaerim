//
//  FrameDisplayView.swift
//  QueenCam
//
//  Created by Bora Yun on 11/20/25.
//
import SwiftUI

/// 프레임의 결과만 보여주는 뷰(읽기 전용)
struct FrameDisplayView: View {
  var frameViewModel: FrameViewModel
  /// 프레임에 대한 제스쳐 활성화 가능 여부
  var canInteract: Bool { frameViewModel.canInteract }
  
  var body: some View {
    /// 프레임 내부 및 스트로크(테두리) 색상
    let frameColor: AnyShapeStyle = {
      switch (canInteract) {
      // 현재 프레임을 수정중인 경우
      case (false):
        return AnyShapeStyle(.disabled)
      // 프레임이 수정중이 아닌 경우
      case (true):
        return AnyShapeStyle(
          LinearGradient(
            stops: [
              Gradient.Stop(color: .modelPrimary, location: 0.00),
              Gradient.Stop(color: .photographerPrimary, location: 1.00)
            ],
            startPoint: UnitPoint(x: 0.01, y: 0),
            endPoint: UnitPoint(x: 0.99, y: 1)
          )
        )
      }
    }()
    GeometryReader { geo in
      ForEach(frameViewModel.frames) { frame in
        let rect = frame.rect
        Rectangle()
          .fill(frameColor)  // 프레임의 내부 색상
          .opacity(0.3)
          .overlay(
            Rectangle()
              .stroke(frameColor, style: StrokeStyle(lineWidth: 2, dash: [10, 10]))  // 프레임의 테두리선 색상
          )
          .frame(width: rect.width * geo.size.width, height: rect.height * geo.size.height)
          .position(
            x: (rect.minX + rect.width / 2) * geo.size.width,
            y: (rect.minY + rect.height / 2) * geo.size.height
          )
      }
    }
  }
}
