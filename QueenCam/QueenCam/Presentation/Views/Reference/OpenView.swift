//
//  OpenView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//
//  Camera Preview에서 제시되는 레퍼런스 사진 View

import SwiftUI

struct OpenView: View {
  @ObservedObject var viewModel : ReferenceViewModel
  @State private var showDelete: Bool = false

  let role: Role?

  var body: some View {
    ZStack(alignment: .topTrailing) {
      RoundedRectangle(cornerRadius: 20)
        .fill(.yellow)
        .frame(width: 90, height: 120)
        .onTapGesture {
          guard role == .model else { return } // 작가의 경우 레퍼런스 삭제 불가능
          showDelete.toggle() //모델의 경우 레퍼런스 삭제 가능
        }

      if showDelete {
        Button {
          viewModel.onDelete()
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
  OpenView(viewModel: ReferenceViewModel(), role: .model)
}
