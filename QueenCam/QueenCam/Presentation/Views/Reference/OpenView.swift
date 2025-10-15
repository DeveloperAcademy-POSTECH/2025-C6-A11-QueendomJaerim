//
//  OpenView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//
//  Camera Preview에서 제시되는 레퍼런스 사진 View

import SwiftUI

struct OpenView: View {
  @StateObject private var viewModel = ReferenceViewModel()
  @State private var showDelete : Bool = false
  var body: some View {
    ZStack(alignment: .topTrailing) {
      RoundedRectangle(cornerRadius: 20)
        .fill(.yellow)
        .frame(width: 90, height: 120)
        .onTapGesture {
          showDelete.toggle()
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
  OpenView()
}
