//
//  CloseView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//  Camera Preview에서 레퍼런스를 Fold 했을때 나타나는 View

import SwiftUI

struct CloseView: View {
  @Bindable var referenceViewModel: ReferenceViewModel

  private var isLeading: Bool {
    referenceViewModel.location == .topLeft || referenceViewModel.location == .bottomLeft
  }

  private var cornerRadii: RectangleCornerRadii {
    if isLeading {
      RectangleCornerRadii(
        topLeading: 0,
        bottomLeading: 0,
        bottomTrailing: 24,
        topTrailing: 24
      )
    } else {
      RectangleCornerRadii(
        topLeading: 24,
        bottomLeading: 24,
        bottomTrailing: 0,
        topTrailing: 0
      )
    }
  }

  private var chevronSystemName: String {
    isLeading ? "chevron.compact.right" : "chevron.compact.left"
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(.offWhite.opacity(0.4))
        .frame(width: 22, height: 101)
        .glassEffect(
          .clear,
          in: .rect(cornerRadii: cornerRadii)
        )
        .clipShape(
          UnevenRoundedRectangle(cornerRadii: cornerRadii)
        )
      Image(systemName: chevronSystemName)
        .foregroundStyle(.offWhite)
        .font(.system(size: 30, weight: .regular))
    }
  }
}
