//
//  CloseView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//  Camera Preview에서 레퍼런스를 Fold 했을때 나타나는 View

import SwiftUI

struct CloseView: View {
  var body: some View {
    ZStack {
      Rectangle()
        .fill(.black.opacity(0.8))
        .frame(width: 28, height: 120)
        .clipShape(UnevenRoundedRectangle(
          cornerRadii: RectangleCornerRadii(
            topLeading: 0, bottomLeading: 0, bottomTrailing: 10, topTrailing: 10
          ),
        ))
      Image(systemName: "chevron.right")
        .foregroundStyle(.white)
    }
  }
}

#Preview {
  CloseView()
}
