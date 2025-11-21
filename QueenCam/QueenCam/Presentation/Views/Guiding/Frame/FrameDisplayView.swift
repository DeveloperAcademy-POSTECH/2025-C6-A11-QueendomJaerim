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
  var currentRole: Role?

  var body: some View {
    // 프레임이 켜져 있고, 프레임 소유자가 나와 다르면 나는 비활성(=상대가 소유 중)
    let disabledByPeer = frameViewModel.isFrameEnabled && frameViewModel.frameOwnerRole != currentRole

    // 프레임 내부 및 스트로크(테두리) 색상
    let frameColor: AnyShapeStyle = {
      if disabledByPeer {
        // 상대가 소유 중(내 버튼이 비활성)일 때: 흰색
        return AnyShapeStyle(.offWhite)
      } else {
        // 내가 소유자이거나, 소유자 없음/꺼짐: 그라디언트
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
