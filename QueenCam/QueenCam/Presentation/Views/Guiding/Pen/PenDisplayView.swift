//
//  PenDisplayView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.

import Foundation
import SwiftUI

/// 저장된 펜 가이드라인 조회(출력) 뷰
struct PenDisplayView: View {
  var penViewModel: PenViewModel

  init(penViewModel: PenViewModel) {
    self.penViewModel = penViewModel
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        // MARK: - 세션 종료 persistedStrokes
        let normalPersistedStrokes = penViewModel.persistedStrokes.filter {
          $0.points.count > 1 && !$0.isMagicPen
        }
        let magicPenPersistedStrokes = penViewModel.strokes.filter {
          $0.points.count > 1 && $0.isMagicPen
        }
        ForEach(normalPersistedStrokes, id: \.id) { stroke in
          SingleStrokeView(penViewModel: penViewModel, roleForTheme: stroke.author, geoSize: geo.size, stroke: stroke)
        }
        ForEach(magicPenPersistedStrokes, id: \.id) { stroke in
          SingleMagicStrokeView(penViewModel: penViewModel, roleForTheme: stroke.author, geoSize: geo.size, stroke: stroke)
            .transition(.opacity)
        }
        
        // MARK: - 세션 중 그리기 완료된 strokes
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
            .transition(.opacity)
        }
      }
      .background(.clear)
      .allowsHitTesting(false)
      .animation(.easeInOut(duration: 0.3), value: penViewModel.strokes)  // 사라짐 애니메이션
    }
  }
}
