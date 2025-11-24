//
//  ReconnectingView.swift
//  QueenCam
//
//  Created by 임영택 on 10/25/25.
//

import SwiftUI

struct ReconnectingView {
  let didCancelButtonTap: () -> Void

  private let progressViewSize: CGFloat = 30
}

extension ReconnectingView: View {
  var body: some View {
    VStack(spacing: 0) {
      ProgressView()
        .tint(.offWhite)
        .frame(width: progressViewSize, height: progressViewSize)
        .padding(.bottom, 24)

      Text("연결 상태가 좋지 않아,\n다시 연결하고 있어요.")
        .foregroundStyle(.offWhite)
        .typo(.m15)
        .multilineTextAlignment(.center)
        .padding(.bottom, 32)

      Button(action: didCancelButtonTap) {
        Text("연결 취소하기")
          .underline()
          .foregroundStyle(.gray200)
          .typo(.m13)
      }
      .buttonStyle(.plain)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      .originalBlack
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

    ReconnectingView {}
  }
}
