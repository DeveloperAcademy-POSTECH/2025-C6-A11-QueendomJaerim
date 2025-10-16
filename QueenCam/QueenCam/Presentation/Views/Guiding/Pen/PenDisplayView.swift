//
//  PenDisplayView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//

import SwiftUI

struct PenDisplayView: View {
  let strokes: [Pen]
    var body: some View {
      GeometryReader { _ in
        Canvas { context, _ in
          for stroke in strokes where stroke.points.count > 1 {
            var path = Path();
            path.addLines(stroke.points)
            context.stroke(path, with: .color(.white), style: .init(lineWidth: 8, lineCap: .round, lineJoin: .round))
            context.stroke(path, with: .color(.white), style: .init(lineWidth: 4, lineCap: .round, lineJoin: .round))
          }
        }
        .background(.clear)
      }
    }
}

//#Preview {
//    PenDisplayView()
//}
