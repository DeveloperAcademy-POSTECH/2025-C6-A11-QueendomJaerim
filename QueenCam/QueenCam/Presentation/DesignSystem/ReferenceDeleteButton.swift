//
//  circletest.swift
//  QueenCam
//
//  Created by Bora Yun on 10/31/25.
//

import SwiftUI

struct ReferenceDeleteButton: View {
    var body: some View {
      ZStack(alignment: .center){
        Circle()
          .fill(.offWhite.opacity(0.7))
          .frame(width: 24, height: 24)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .inset(by: 0.5)
              .stroke(.offWhite, lineWidth: 1)
          )
          .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 0)
          
        Image(systemName: "xmark")
          .foregroundStyle(.gray900)
          .font(.system(size: 13, weight: .regular))
      }
    }
}

#Preview {
  ReferenceDeleteButton()
}
