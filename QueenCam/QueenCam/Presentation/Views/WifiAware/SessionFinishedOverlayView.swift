//
//  SessionFinishedOverlayView.swift
//  QueenCam
//
//  Created by 임영택 on 11/05/25.
//

import SwiftUI

struct SessionFinishedOverlayView {
  let didCancelButtonTap: () -> Void

  private let backgroundColor = Color.black.opacity(0.7)
}

extension SessionFinishedOverlayView: View {
  var body: some View {
    VStack {
      Text("친구가 연결을 종료했어요.\n다시 시작하려면 재연결해주세요.")
        .foregroundStyle(.offWhite)
        .multilineTextAlignment(.center)
        .typo(.m13) // FIXME: -> m15

      Spacer()
        .frame(height: 32)

      Button(action: didCancelButtonTap) {
        Text("닫기")
          .foregroundStyle(.offWhite)
          .typo(.m13) // FIXME: -> m15
          .padding(.vertical, 16)
          .padding(.horizontal, 60)
          .background(
            Capsule()
              .foregroundStyle(.clear)
          )
      }
      .glassEffect(.regular)
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

    SessionFinishedOverlayView { }
  }
}
