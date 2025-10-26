//
//  ReconnectingOverlayView.swift
//  QueenCam
//
//  Created by 임영택 on 10/25/25.
//

import SwiftUI

struct ReconnectingOverlayView {
  let didCancelButtonTap: () -> Void

  private let backgroundColor = Color.black.opacity(0.7)
  private let fontColor = Color.white
}

extension ReconnectingOverlayView: View {
  var body: some View {
    VStack {
      Text("다시 연결하고 있어요")
        .foregroundStyle(fontColor)

      Spacer()
        .frame(height: 32)

      Button(action: didCancelButtonTap) {
        Text("취소하기")
      }
      .buttonStyle(.glassProminent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      backgroundColor
    )
  }
}

#Preview {
  ZStack {
    VStack {
      ForEach((65..<88), id: \.self) { dummyCode in
        if let unicodeScalr = UnicodeScalar(dummyCode) {
          HStack {
            Spacer()
            Text("\(String(Character(unicodeScalr)))")
            Spacer()
            Text("\(String(Character(unicodeScalr)))")
            Spacer()
            Text("\(String(Character(unicodeScalr)))")
            Spacer()
          }
        }
      }
    }

    ReconnectingOverlayView { }
  }
}
