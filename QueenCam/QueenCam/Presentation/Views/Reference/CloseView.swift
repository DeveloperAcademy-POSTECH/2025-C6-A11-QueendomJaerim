//
//  CloseView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//  Camera Preview에서 레퍼런스를 Fold 했을때 나타나는 View

import SwiftUI

struct CloseView: View {
  @Bindable var referenceViewModel: ReferenceViewModel

  var body: some View {
    ZStack {
      if referenceViewModel.alignment == .bottomLeading || referenceViewModel.alignment == .topLeading {
        Rectangle()
          .fill(.black.opacity(0.8))
          .frame(width: 28, height: 120)
          .clipShape(
            UnevenRoundedRectangle(
              cornerRadii: RectangleCornerRadii(
                topLeading: 0,
                bottomLeading: 0,
                bottomTrailing: 10,
                topTrailing: 10
              ),
            )
          )
        Image(systemName: "chevron.right")
          .foregroundStyle(.white)
      } else {
        Rectangle()
          .fill(.black.opacity(0.8))
          .frame(width: 28, height: 120)
          .clipShape(
            UnevenRoundedRectangle(
              cornerRadii: RectangleCornerRadii(
                topLeading: 10,
                bottomLeading: 10,
                bottomTrailing: 0,
                topTrailing: 0
              ),
            )
          )
        Image(systemName: "chevron.left")
          .foregroundStyle(.white)
      }
    }
  }

}

