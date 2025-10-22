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
  @State private var isLarge: Bool = false
  
  let regularWidth: CGFloat = 90
  let regularHeight: CGFloat = 120
  let largeWidth: CGFloat = 151
  let largeHeight: CGFloat = 202
  let role: Role?

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Group {
        if let image = referenceViewModel.image {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(
              width: isLarge ? largeWidth: regularWidth,
              height: isLarge ? largeHeight: regularHeight
            )
            .clipShape(.rect(cornerRadius: 20))
            .onTapGesture {
              isLarge.toggle()
              guard role == .model else { return }  // 작가의 경우 레퍼런스 삭제 불가능
              showDelete.toggle()  //모델의 경우 레퍼런스 삭제 가능
            }
        }
      }
      if isLarge {
        //TODO: - Dimming 효과 추가
        
      }
      if showDelete && (referenceViewModel.image != nil) {
        Button {
          referenceViewModel.onDelete()
          showDelete = false
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
  OpenView(referenceViewModel: ReferenceViewModel(), role: .model)
}
