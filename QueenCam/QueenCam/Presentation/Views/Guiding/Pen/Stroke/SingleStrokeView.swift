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
      let style = StrokeRenderStyleResolver.normalStrokeStyle(for: stroke.author)
      let path = StrokeOverlayGeometry.path(from: stroke.points, in: geoSize)
      context.stroke(
        path,
        with: .color(style.backgroundColor),
        style: style.backgroundStrokeStyle
      )
      context.stroke(
        path,
        with: .color(style.foregroundColor),
        style: style.foregroundStrokeStyle
      )
    }
  }
}
