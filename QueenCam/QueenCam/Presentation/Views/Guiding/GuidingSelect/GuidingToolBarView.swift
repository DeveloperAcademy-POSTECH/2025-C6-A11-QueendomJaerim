//
//  SwiftUIView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//

import SwiftUI

struct GuidingToolBarView: View {
  var onAction: (ToolBarAction) -> Void
  var body: some View {
    HStack(spacing: 20) {
      // 전체 삭제
      PenToolButton(penToolType: .eraser, isActive: true, tapAction: {
        onAction(.clearAll)
      })
      
      // 실행 취소
      PenToolButton(penToolType: .undo, isActive: true, tapAction: {
        onAction(.undo)
      })
    }
  }
}

#Preview {
  GuidingToolBarView { action in
    print("Tapped: \(action)")
  }
}
