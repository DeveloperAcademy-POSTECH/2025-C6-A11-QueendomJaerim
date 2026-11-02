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
    let role: Role?
    @ViewBuilder let menuContent: () -> IndicatorMenuContent
    let notConnectedButtonDidTap: () -> Void

    var body: some View {
      if let connectedDeviceName {
        WhenCurrentlyConnectedIndicatorView(
          connectedDeviceName: connectedDeviceName,
          role: role,
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
    let role: Role?
    @ViewBuilder let menuContent: () -> IndicatorMenuContent
    let buttonDidTap: () -> Void

    private let indicatorSize: CGFloat = 6
  }
}

extension TopToolBarView.WhenCurrentlyConnectedIndicatorView: View {
  private var indicatorColor: Color {
    role == .model ? .modelPrimary : .photographerPrimary
  }

  var menuLabel: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(indicatorColor)
        .frame(width: indicatorSize, height: indicatorSize)

      // 상대 기기 이름
      Text(connectedDeviceName)
        .lineLimit(1)
        .foregroundStyle(.offWhite)
        .typo(.r12)
    }
    .padding(.leading, 12)
    .padding(.trailing, 14)
    .padding(.vertical, 9)
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

    private let chevronSize: CGFloat = 8
  }
}

extension TopToolBarView.WhenNotConnectedIndicatorView: View {
  var body: some View {
    Button(action: buttonDidTap) {
      HStack(spacing: 8) {
        Text("기기 연결하기")
          .foregroundStyle(.offWhite)
          .typo(.r12)

        Image(systemName: "chevron.right")
          .font(.system(size: chevronSize))
          .foregroundStyle(.offWhite)
      }
      .padding(.leading, 14)
      .padding(.trailing, 12)
      .padding(.vertical, 9)
      .glassEffect()
    }
  }
}
