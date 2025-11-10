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
        let normalStrokes = penViewModel.strokes.filter {
          $0.points.count > 1 && !$0.isMagicPen
        }
        let magicPenStrokes = penViewModel.strokes.filter {
          $0.points.count > 1 && $0.isMagicPen
        }
        ForEach(normalStrokes, id: \.self) { stroke in
          SingleStrokeView(penViewModel: penViewModel, roleForTheme: stroke.author, geoSize: geo.size, stroke: stroke)
        }
        ForEach(magicPenStrokes, id: \.self) { stroke in
          SingleMagicStrokeView(penViewModel: penViewModel, roleForTheme: stroke.author, geoSize: geo.size, stroke: stroke)
        }
      }
      .background(.clear)
      .allowsHitTesting(false)
    }
  }
}
