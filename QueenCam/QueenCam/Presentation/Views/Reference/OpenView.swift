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
          ZStack(alignment: .center){
            Circle()
              .background(.offWhite.opacity(0.6))
              .frame(width: 24, height: 24)
              .overlay(
                Circle()
                  .background(.offWhite.opacity(0.7))
              )
              .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 0)
              
            Image(systemName: "xmark")
              .foregroundStyle(.gray900)
              .font(.system(size: 13, weight: .regular))
          }
        }
        .padding(4)
      }
    }
  }
}
