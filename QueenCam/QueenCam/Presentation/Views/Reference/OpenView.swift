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

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Group {
        if let image = referenceViewModel.image {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(
              width: !isLarge
              ? ReferenceSize.referenceRatio(width: image.size.width, height: image.size.height).width
              : ReferenceSize.referenceRatio(width: image.size.width, height: image.size.height).width*2
            )
            .clipShape(.rect(cornerRadius: 20))
            .onTapGesture {
              isLarge.toggle()
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
          ReferenceDeleteButton()
        }
        .padding(12)
      }
    }
  }
}
