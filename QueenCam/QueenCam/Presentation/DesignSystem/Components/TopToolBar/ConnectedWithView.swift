//
//  ConnectedWithView.swift
//  QueenCam
//
//  Created by 임영택 on 10/30/25.
//

import SwiftUI

struct ConnectedWithView: View {
  let isConnected: Bool
  let connectedDeviceName: String?
  let buttonDidTap: () -> Void

  var body: some View {
    if isConnected {
      WhenCurrentlyConnected(connectedDeviceName: connectedDeviceName ?? "알 수 없는 기긴", buttonDidTap: buttonDidTap)
    } else {
      WhenNotConnected(buttonDidTap: buttonDidTap)
    }
  }
}

private struct WhenCurrentlyConnected: View {
  let connectedDeviceName: String
  let buttonDidTap: () -> Void

  private let horizontalSpacer: some View = Spacer().frame(width: 28)
  private let minWidth: CGFloat = 48
  private let height: CGFloat = 48

  var body: some View {
    Button(action: buttonDidTap) {
      HStack(spacing: 0) {
        horizontalSpacer

        VStack(spacing: 4) {
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
      .frame(minWidth: minWidth, minHeight: height)
      .glassEffect()
    }
  }
}

private struct WhenNotConnected: View {
  let buttonDidTap: () -> Void

  private let buttonLabelFont = Font.pretendard(.medium, size: 17)
  private let width: CGFloat = 162
  private let height: CGFloat = 48

  var body: some View {
    Button(action: buttonDidTap) {
      VStack {
        HStack {
          Text("기기 연결하기")
            .foregroundStyle(.white)
            .font(buttonLabelFont)
        }
      }
      .frame(width: width, height: height)
      .glassEffect()
    }
  }
}

#Preview {
  ZStack {
    Color.black

    VStack {
      ConnectedWithView(
        isConnected: true,
        connectedDeviceName: "임영폰"
      ) {
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }

      ConnectedWithView(
        isConnected: true,
        connectedDeviceName: "임영택의 iPhone"
      ) {
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }

      ConnectedWithView(
        isConnected: true,
        connectedDeviceName: "임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 "
      ) {
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }

      ConnectedWithView(isConnected: true, connectedDeviceName: nil) { // 재연결시 가끔 이럴 때가 있음
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }

      ConnectedWithView(isConnected: false, connectedDeviceName: nil) {
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }
    }
  }
}
