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

  let horizontalSpacer: some View = Spacer().frame(width: 28)

  var body: some View {
    Button(action: buttonDidTap) {
      VStack(spacing: 4) {
        HStack(spacing: 0) {
          horizontalSpacer

          VStack {
            // Subtitle
            Text("연결된 기기")
              .foregroundStyle(.gray400)
              .typo(.m10)

            // 상대 기기 이름
            Text(connectedDeviceName)
              .lineLimit(1)
              .foregroundStyle(.white)
              .typo(.m13)
          }

          horizontalSpacer
        }
      }
      .frame(minWidth: minWidth, minHeight: height)
      .glassEffect()
    }
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

      ConnectedWithView(connectedDeviceName: "임영택의 iPhone") {
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
