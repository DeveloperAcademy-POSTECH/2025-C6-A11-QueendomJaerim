//
//  CameraView+ToggleToolboxButton.swift
//  QueenCam
//
//  Created by 임영택 on 11/12/25.
//

import SwiftUI

extension CameraView {
  struct ToggleToolboxButton: View {
    let size: CGFloat = 34
    let action: () -> Void

    var body: some View {
      Button(action: action) {
        Circle()
          .fill(.black.opacity(0.5))
          .frame(width: size, height: size)
          .overlay {
            Image(.toolbox)
              .resizable()
              .renderingMode(.template)
              .foregroundStyle(.originalWhite)
              .scaledToFit()
              .frame(width: 13)
          }
      }
    }
  }
}

#Preview {
  CameraView.ToggleToolboxButton {
    //
  }
}
