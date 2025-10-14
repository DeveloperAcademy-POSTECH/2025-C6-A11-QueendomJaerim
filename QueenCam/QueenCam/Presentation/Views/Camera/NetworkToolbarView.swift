//
//  NetworkToolbarView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import SwiftUI

struct NetworkToolbarView: View {
  let networkState: NetworkState?
  let connectedDeviceName: String?
  let buttonDidTap: () -> Void

  var body: some View {
    HStack {
      Spacer()

      Button {
        buttonDidTap()
      } label: {
        if networkState == nil || networkState == .host(.stopped) || networkState == .viewer(.stopped) {
          NetworkToolbarButtonLabel(isDotShowing: false, title: "연결하기")
        } else {
          NetworkToolbarButtonLabel(isDotShowing: true, title: connectedDeviceName ?? "알 수 없는 기기")
        }
      }
      .glassEffect(.regular.tint(.black).interactive())

      Spacer()
    }
  }
}

struct NetworkToolbarButtonLabel: View {
  let isDotShowing: Bool
  let title: String

  var body: some View {
    HStack(spacing: 0) {
      if isDotShowing {
        Circle()
          .foregroundStyle(.red)
          .frame(width: 6, height: 6)

        Spacer()
          .frame(width: 10)
      }

      Text(title)
        .font(.system(size: 16))
        .foregroundStyle(.white)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
  }
}

#Preview {
  VStack {
    NetworkToolbarView(networkState: nil, connectedDeviceName: nil) { print("Button Tapped") }
    // swiftlint:disable:next no_print_in_production
    NetworkToolbarView(networkState: .host(.stopped), connectedDeviceName: nil) { print("Button Tapped") }
    // swiftlint:disable:next no_print_in_production
    NetworkToolbarView(networkState: .host(.publishing), connectedDeviceName: "윤보라의 iPhone 17 Air") { print("Button Tapped") }
    // swiftlint:disable:next no_print_in_production
    NetworkToolbarView(networkState: .host(.publishing), connectedDeviceName: nil) { print("Button Tapped") }
  }
}
