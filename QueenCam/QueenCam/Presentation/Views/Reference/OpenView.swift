//
//  OpenView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//
//  Camera Preview에서 제시되는 레퍼런스 사진 View

import SwiftUI

struct OpenView: View {
  @Bindable var referenceViewModel: ReferenceViewModel
  @State private var showDelete: Bool = false
  @Binding var isLarge: Bool

  let regularWidth: CGFloat = 90
  let regularHeight: CGFloat = 120
  let largeWidth: CGFloat = 151
  let largeHeight: CGFloat = 202

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Group {
        if let image = referenceViewModel.image {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(
              width: isLarge ? largeWidth : regularWidth,
              height: isLarge ? largeHeight : regularHeight
            )
            .clipShape(.rect(cornerRadius: 20))
            .onTapGesture {
              isLarge = true
              showDelete.toggle()
            }
        }
      }
      if isLarge && (referenceViewModel.image != nil) {
        Button {
          referenceViewModel.onDelete()
          showDelete = false
          isLarge = false
        } label: {
          Image(systemName: "x.circle")
            .imageScale(.large)
        }
        .padding(4)
      }
    }
  }
}

#Preview {
  OpenView(referenceViewModel: ReferenceViewModel(), isLarge: .constant(false))
}
