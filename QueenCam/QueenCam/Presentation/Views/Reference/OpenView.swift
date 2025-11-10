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
          let ratio = ReferenceSize.referenceRatio(width: image.size.width, height: image.size.height)
          /// 원본 이미지의 비율(높이/너비)
          let aspect = image.size.height / image.size.width
          let baseWidth = ratio.width
          /// 레퍼런스의 최종 너비
          let width = isLarge ? baseWidth * 2 : baseWidth
          let baseHeight = baseWidth * aspect
          /// 레퍼런스의 최종 높이
          let height: CGFloat = {
            switch ratio {
            case .ratio16x9:
              return isLarge ? 160 * 2 : 160
            case .ratio9x16:
              return isLarge ? 90 * 2 : 90
            default:
              return isLarge ? baseHeight * 2 : baseHeight
            }
          }()

          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height, alignment: .center)
            .glassEffect( .clear, in: .rect(cornerRadius: 24))
            .clipShape(.rect(cornerRadius: 24))
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
