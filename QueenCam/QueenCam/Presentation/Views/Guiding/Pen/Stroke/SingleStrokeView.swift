//
//  SingleStrokeView.swift
//  QueenCam
//
//  Created by Bora Yun on 11/10/25.
//
import Foundation
import SwiftUI

/// 일반펜에 해당하는 stroke의 View
struct SingleStrokeView: View {
  var penViewModel: PenViewModel
  let roleForTheme: Role?
  let geoSize: CGSize
  let stroke: Stroke
  
  var body: some View {
    Canvas { context, _ in
      let outerColor = (stroke.author == .model) ? Color.modelPrimary : .photographerPrimary
      var path = Path()
      path.addLines(stroke.absolutePoints(in: geoSize))
      context.stroke(
        path,
        with: .color(.offWhite),
        style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        path,
        with: .color(outerColor),
        style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round)
      )
    }
  }
}

