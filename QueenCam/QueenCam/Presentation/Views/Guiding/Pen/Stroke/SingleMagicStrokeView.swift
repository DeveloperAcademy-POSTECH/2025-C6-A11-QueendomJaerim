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
  var body: some View {
    let outerColor = (stroke.author == .model) ? Color.modelPrimary : .photographerPrimary
    
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
        with: .color(.offWhite),
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
          with: .color(.offWhite),
          style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }
  }
}
