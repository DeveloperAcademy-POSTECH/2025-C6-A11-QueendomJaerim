//
//  SingleMagicStrokeView.swift
//  QueenCam
//
//  Created by Bora Yun on 11/11/25.
//
import Foundation
import SwiftUI

/// 매직펜에 해당하는 stroke의 View
struct SingleMagicStrokeView: View {
  var penViewModel: PenViewModel
  let roleForTheme: Role?
  let geoSize: CGSize
  let stroke: Stroke

  // 사라지는 애니메이션을 위해 필요한 요소들
  @State private var opacity: Double = 1.0
  private let magicAfter: TimeInterval = 0.7
  private let fadeDuration: TimeInterval = 0.3

  var body: some View {
    let outerColor = (stroke.author == .model) ? Color.modelPrimary : .photographerPrimary

    ZStack {
      // 매직펜의 Blur 레이어

      Canvas { context, _ in
        var path = Path()
        path.addLines(stroke.absolutePoints(in: geoSize))

        context.stroke(
          path,
          with: .color(outerColor),
          style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
          path,
          with: .color(.systemWhite),
          style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
        )
      }
      .drawingGroup()
      .blur(radius: 4)

      // 매직펜의 !Blur 레이어
      Canvas { context, _ in
        var path = Path()
        path.addLines(stroke.absolutePoints(in: geoSize))

        context.stroke(
          path,
          with: .color(.systemWhite),
          style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
      }
    }
    .opacity(opacity)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + magicAfter) {
        withAnimation(.easeInOut(duration: fadeDuration)) {
          opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
          penViewModel.remove(stroke.id)
        }
      }
    }
  }
}
