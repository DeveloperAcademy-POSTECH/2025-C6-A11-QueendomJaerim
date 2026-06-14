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
      StrokeOverlayRenderer.drawNormalStroke(
        points: stroke.points,
        author: stroke.author,
        in: context,
        size: geoSize
      )
    }
  }
}
