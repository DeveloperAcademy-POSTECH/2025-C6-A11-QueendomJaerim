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

  private var myRole: Role {
    penViewModel.currentRole ?? .photographer
  }
  private var myStrokes: [Stroke] {
    penViewModel.strokes.filter { $0.author == myRole }
  }
  private var myDeleteStrokes: [[Stroke]] {
    penViewModel.deleteStrokes
      .map { group in group.filter { $0.author == myRole } }
      .filter { !$0.isEmpty }
  }

  // 버튼 활성 조건(내가 그린 것만 기준)
  private var isEraserActive: Bool {
    !myStrokes.isEmpty
  }
  private var isUndoActive: Bool {
    !(myDeleteStrokes.isEmpty && myStrokes.isEmpty)
  }

  var body: some View {

    HStack(spacing: .zero) {
      // 실행 취소(내가 그린 현재 strokes가 있거나, 내가 방금 전체삭제한 기록이 있으면 활성)
      PenToolButton(
        penToolType: .undo,
        isActive: isUndoActive
      ) {
        onAction(.undo)
      }
      .padding(.trailing, 26)
      
      
      // 전체 삭제(내가 그린 것만 존재할 때 활성)
      PenToolButton(
        penToolType: .eraser,
        isActive: isEraserActive
      ) {
        onAction(.deleteAll)
      }
    }
  }
}

#Preview {
  PenToolBar(penViewModel: PenViewModel()) { action in
    // swiftlint:disable:next no_print_in_production
    print("Tapped: \(action)")
  }
}
