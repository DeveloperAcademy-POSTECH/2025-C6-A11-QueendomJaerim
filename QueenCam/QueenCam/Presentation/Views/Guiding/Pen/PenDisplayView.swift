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
  private var outerColor = Color.white
  private var modelColor = Color.orange
  private var photographerColor = Color.blue

  init(penViewModel: PenViewModel, role: Role?) {
    self.penViewModel = penViewModel
    self.role = role
  }

  var body: some View {
    GeometryReader { geo in
      Canvas { context, _ in
        for stroke in penViewModel.strokes where stroke.points.count > 1 {
          var path = Path()
          path.addLines(stroke.absolutePoints(in: geo.size))
          context.stroke(path, with: .color(outerColor), style: .init(lineWidth: 8, lineCap: .round, lineJoin: .round))
          let inner = stroke.author == .model ? modelColor : photographerColor
          context.stroke(path, with: .color(inner), style: .init(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }
      }
      .background(.clear)
      .allowsHitTesting(false)
    }
  }
}
