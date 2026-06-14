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
  let penPhotoOverlayComposer: PenPhotoOverlayComposer
  let isVisibleInPhotoOverlay: Bool

  init(
    penViewModel: PenViewModel,
    penPhotoOverlayComposer: PenPhotoOverlayComposer,
    isVisibleInPhotoOverlay: Bool
  ) {
    self.penViewModel = penViewModel
    self.penPhotoOverlayComposer = penPhotoOverlayComposer
    self.isVisibleInPhotoOverlay = isVisibleInPhotoOverlay
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        // MARK: - 세션 종료된 일반펜 persistedStrokes
        let normalPersistedStrokes = penViewModel.persistedStrokes.filter {
          $0.points.count > 1 && !$0.isMagicPen
        }
        ForEach(normalPersistedStrokes, id: \.id) { stroke in
          SingleStrokeView(penViewModel: penViewModel, roleForTheme: stroke.author, geoSize: geo.size, stroke: stroke)
        }

        // MARK: - 세션 중 그리기 완료된 strokes
        let normalStrokes = penViewModel.strokes.filter {
          $0.points.count > 1 && !$0.isMagicPen
        }
        let magicPenStrokes = penViewModel.strokes.filter {
          $0.points.count > 1 && $0.isMagicPen
        }
        ForEach(normalStrokes, id: \.id) { stroke in
          SingleStrokeView(penViewModel: penViewModel, roleForTheme: stroke.author, geoSize: geo.size, stroke: stroke)
        }
        ForEach(magicPenStrokes, id: \.id) { stroke in
          SingleMagicStrokeView(penViewModel: penViewModel, roleForTheme: stroke.author, geoSize: geo.size, stroke: stroke)
            .transition(.opacity)
        }
      }
      .background(.clear)
      .allowsHitTesting(false)
      .onAppear {
        syncPhotoOverlayStrokes()
      }
      .onChange(of: penViewModel.persistedStrokes) { _, _ in
        syncPhotoOverlayStrokes()
      }
      .onChange(of: penViewModel.strokes) { _, _ in
        syncPhotoOverlayStrokes()
      }
      .onChange(of: isVisibleInPhotoOverlay) { _, _ in
        syncPhotoOverlayStrokes()
      }
    }
  }
}

private extension PenDisplayView {
  var visiblePhotoOverlayStrokes: [Stroke] {
    let normalPersistedStrokes = penViewModel.persistedStrokes.filter {
      $0.points.count > 1 && !$0.isMagicPen
    }
    let visibleSessionStrokes = penViewModel.strokes.filter {
      $0.points.count > 1
    }

    return normalPersistedStrokes + visibleSessionStrokes
  }

  func syncPhotoOverlayStrokes() {
    guard isVisibleInPhotoOverlay else {
      penPhotoOverlayComposer.clear()
      return
    }

    penPhotoOverlayComposer.replaceVisibleStrokes(visiblePhotoOverlayStrokes)
  }
}
