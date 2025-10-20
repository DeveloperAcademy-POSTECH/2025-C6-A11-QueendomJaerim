//
//  CircleButton.swift
//  QueenCam
//
//  Created by Bora Yun on 10/20/25.
//

import SwiftUI

struct CircleButton: View {
  let systemImage: String
  let isActive: Bool
  let action: () -> Void
    var body: some View {
      Button(action: action) {
        Image(systemName: systemImage)
          .font(.system(size: 22, weight: .semibold))
                  .frame(width: 50, height: 50)
                  .foregroundStyle(isActive ? .white : .white.opacity(0.8))
                  .background(isActive ? Color.orange : Color.clear)
                  .clipShape(Circle())

      }
      .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

#Preview {
  CircleButton(systemImage: "xmark", isActive: true, action: { true })
}
