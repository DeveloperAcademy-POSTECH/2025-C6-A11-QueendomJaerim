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
    @ViewBuilder let menuContent: () -> IndicatorMenuContent
    let notConnectedButtonDidTap: () -> Void

    var body: some View {
      if let connectedDeviceName {
        WhenCurrentlyConnectedIndicatorView(
          connectedDeviceName: connectedDeviceName ?? "알 수 없는 기기",
          menuContent: menuContent,
          buttonDidTap: notConnectedButtonDidTap
        )
      } else {
        WhenNotConnectedIndicatorView(buttonDidTap: notConnectedButtonDidTap)
      }
    }
  }
}

// MARK: - 연결 상태
extension TopToolBarView {
  struct WhenCurrentlyConnectedIndicatorView {
    let connectedDeviceName: String
    @ViewBuilder let menuContent: () -> IndicatorMenuContent
    let buttonDidTap: () -> Void

    private let horizontalSpacer: some View = Spacer().frame(width: 28)
    private let minWidth: CGFloat = 48
    private let height: CGFloat = 48
  }
}

extension TopToolBarView.WhenCurrentlyConnectedIndicatorView: View {
  var menuLabel: some View {
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

  var body: some View {
    Menu {
      Section("연결된 기기") {
        Button(connectedDeviceName) {}
      }

      menuContent()
    } label: {
      menuLabel
    }
    .menuOrder(.fixed)
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
