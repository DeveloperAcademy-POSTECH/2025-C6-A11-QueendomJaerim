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
      //전체 삭제
      Button {
        onAction(.clearAll)
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 25, weight: .semibold))
          .foregroundStyle(.black)
          .frame(width: 60, height: 60)
          .background(.ultraThinMaterial)
          .clipShape(Circle())
          .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
      }

      HStack(spacing: 28) {
        // 실행 취소(Undo)
        Button {
          onAction(.undo)
        } label: {
          Image(systemName: "arrow.uturn.left")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(.black)
        }
        // 재실행(Redo)
        Button {
          onAction(.redo)
        } label: {
          Image(systemName: "arrow.uturn.right")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(.black)
        }
      }.padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
  }
}

#Preview {
  GuidingToolBarView { action in
    print("Tapped: \(action)")
  }
}
