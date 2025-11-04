//
//  SwiftUIView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//

import SwiftUI

struct GuidingToolBarView: View {
  var penViewModel: PenViewModel
  var onAction: (ToolBarAction) -> Void
  var body: some View {

    HStack {
      VStack(alignment: .leading, spacing: 8) {
        // 전체 삭제
        PenToolButton(
          penToolType: .eraser,
          isActive: true,
          tapAction: {
            onAction(.clearAll)
          }
        ).disabled( penViewModel.strokes.isEmpty)

        // 실행 취소
        PenToolButton(
          penToolType: .undo,
          isActive: true,
          tapAction: {
            onAction(.undo)
          }
        ).disabled(penViewModel.strokes.isEmpty)
      }
      Spacer()
    }
    .padding(12)
  }
}

#Preview {
  GuidingToolBarView(penViewModel: PenViewModel()) { action in
    print("Tapped: \(action)")
  }
}
