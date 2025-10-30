//
//  ConnectedWithView.swift
//  QueenCam
//
//  Created by 임영택 on 10/30/25.
//

import SwiftUI

struct ConnectedWithView: View {
  let connectedDeviceName: String
  let buttonDidTap: () -> Void

  private let minWidth: CGFloat = 48
  private let height: CGFloat = 48

  var body: some View {
    Button(action: buttonDidTap) {
      VStack {
        Text("연결된 기기")

        Text(connectedDeviceName)
          .lineLimit(1)
      }
      .frame(minWidth: minWidth, minHeight: height)
    }
    .buttonStyle(.glass)
  }
}

#Preview {
  ZStack {
    Color.black

    VStack {
      ConnectedWithView(connectedDeviceName: "임영폰") {
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }

      ConnectedWithView(connectedDeviceName: "임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 ") {
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }
    }
  }
}
