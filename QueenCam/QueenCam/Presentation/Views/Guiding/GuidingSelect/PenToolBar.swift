//
//  SwiftUIView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//

import SwiftUI

struct PenToolBar: View {
  var penViewModel: PenViewModel
  var onAction: (ToolBarAction) -> Void
  var body: some View {

    HStack {
      VStack(alignment: .leading, spacing: 8) {
        // 전체 삭제
        PenToolButton(
          penToolType: .eraser,
          isActive: !penViewModel.strokes.isEmpty,
          tapAction: {
            onAction(.deleteAll)
          }
        )

        // 실행 취소
        PenToolButton(
          penToolType: .undo,
          isActive: !(penViewModel.deleteStrokes.isEmpty && penViewModel.strokes.isEmpty),
          tapAction: {
            onAction(.undo)
          }
        )
      }
      Spacer()
    }
    .padding(12)
  }
}

#Preview {
  PenToolBar(penViewModel: PenViewModel()) { action in
    print("Tapped: \(action)")
  }
}
