//
//  PenDisplayView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.

import Observation
import SwiftUI

/// 저장된 펜 가이드라인 조회(출력) 뷰 (Both)
struct PenDisplayView: View {
  var penViewModel: PenViewModel
  let role: Role?
  private var topColor = Color.offWhite
  private var photographerColor = Color.photographerPrimary
  private var modelColor = Color.modelPrimary

  init(penViewModel: PenViewModel, role: Role?) {
    self.penViewModel = penViewModel
    self.role = role
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {

        // 1) 일반 펜 전용 Canvas
        Canvas { context, _ in
          for stroke in penViewModel.strokes where stroke.points.count > 1 && !stroke.isMagicPen {
            let outerColor = (stroke.author == .model) ? modelColor : photographerColor

            var path = Path()
            path.addLines(stroke.absolutePoints(in: geo.size))

            context.stroke(
              path,
              with: .color(topColor),
              style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
            )
            context.stroke(
              path,
              with: .color(outerColor),
              style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
            )
          }
        }
        .background(.clear)

        // 2) 매직펜 전용 Canvas1: Blur 레이어
        Canvas { context, _ in
          for stroke in penViewModel.strokes where stroke.points.count > 1 && stroke.isMagicPen {
            let outerColor = (stroke.author == .model) ? modelColor : photographerColor

            var path = Path()
            path.addLines(stroke.absolutePoints(in: geo.size))

            context.stroke(
              path,
              with: .color(outerColor),
              style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
            )
            // 안쪽 offWhite 얇게
            context.stroke(
              path,
              with: .color(.offWhite),
              style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
            )
          }
        }
        .drawingGroup()
        .blur(radius: 4)

        // 3) 매직펜 전용 Canvas2: Top 하이라이트 (Blur 없음)
        Canvas { context, _ in
          for stroke in penViewModel.strokes where stroke.points.count > 1 && stroke.isMagicPen {
            var path = Path()
            path.addLines(stroke.absolutePoints(in: geo.size))

            context.stroke(
              path,
              with: .color(.offWhite),
              style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
          }
        }
      }
      .background(.clear)
      .allowsHitTesting(false)
    }
  }
}
