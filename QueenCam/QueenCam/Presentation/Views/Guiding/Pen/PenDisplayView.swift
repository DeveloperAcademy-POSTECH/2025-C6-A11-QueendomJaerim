//
//  PenDisplayView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.

import Observation
import SwiftUI

/// 저장된 펜 가이드라인 조회(출력) 뷰 (Both)
struct PenDisplayView: View {
  var penViewModel = PenViewModel()
  private var outerColor = Color.white
  private var innerColor = Color.orange
  var body: some View {
    GeometryReader { _ in
      Canvas { context, _ in
        for stroke in penViewModel.strokes where stroke.points.count > 1 {
          var path = Path()
          path.addLines(stroke.points)
          context.stroke(path, with: .color(outerColor), style: .init(lineWidth: 8, lineCap: .round, lineJoin: .round))
          context.stroke(path, with: .color(innerColor), style: .init(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }
      }
      .background(.clear)
      .allowsHitTesting(false)
    }
  }
}
