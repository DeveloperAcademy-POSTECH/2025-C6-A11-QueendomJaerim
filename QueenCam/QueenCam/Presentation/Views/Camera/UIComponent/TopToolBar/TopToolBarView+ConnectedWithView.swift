//
//  TopToolBarView+ConnectedWithView.swift
//  QueenCam
//
//  Created by 임영택 on 10/30/25.
//

import SwiftUI

extension TopToolBarView {
  struct ConnectedWithView: View {
    let connectedDeviceName: String?
    let buttonDidTap: () -> Void

    var body: some View {
      if let connectedDeviceName {
        WhenCurrentlyConnectedIndicatorView(connectedDeviceName: connectedDeviceName, buttonDidTap: buttonDidTap)
      } else {
        WhenNotConnectedIndicatorView(buttonDidTap: buttonDidTap)
      }
    }
  }
}

// MARK: - 연결 상태
extension TopToolBarView {
  struct WhenCurrentlyConnectedIndicatorView {
    let connectedDeviceName: String
    let buttonDidTap: () -> Void

    private let horizontalSpacer: some View = Spacer().frame(width: 28)
    private let minWidth: CGFloat = 48
    private let height: CGFloat = 48
  }
}

extension TopToolBarView.WhenCurrentlyConnectedIndicatorView: View {
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

// MARK: - 미연결 상태
extension TopToolBarView {
  struct WhenNotConnectedIndicatorView {
    let buttonDidTap: () -> Void

    private let buttonLabelFont = Font.pretendard(.medium, size: 17)
    private let width: CGFloat = 162
    private let height: CGFloat = 48
  }
}

extension TopToolBarView.WhenNotConnectedIndicatorView: View {
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
      TopToolBarView<AnyView>.ConnectedWithView(
        connectedDeviceName: "임영폰"
      ) {
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }

      TopToolBarView<AnyView>.ConnectedWithView(
        connectedDeviceName: "임영택의 iPhone"
      ) {
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }

      TopToolBarView<AnyView>.ConnectedWithView(
        connectedDeviceName: "임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 임영폰 "
      ) {
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }

      TopToolBarView<AnyView>.ConnectedWithView(connectedDeviceName: nil) {
        // swiftlint:disable:next no_print_in_production
        print("Tapped!")
      }
    }
  }
}
