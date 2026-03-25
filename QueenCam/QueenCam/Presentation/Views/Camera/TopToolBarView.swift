//
//  TopToolBarView.swift
//  QueenCam
//
//  Created by 임영택 on 10/30/25.
//

import SwiftUI

/// Top Tool Bar
struct TopToolBarView<IndicatorMenuContent: View> {
  /// 연결된 디바이스 이름 (연결이 끊어졌으면 nil)
  let connectedDeviceName: String?

  /// 재연결 중인 디바이스 이름 (연결이 끊어졌지만 재연결 중이면 nil이 아님)
  let reconnectingDeviceName: String?

  /// 가운데 연결 메뉴 아이템
  @ViewBuilder let indicatorMenuContent: () -> IndicatorMenuContent

  /// 현재 연결 기기 버튼 액션
  let connectedWithButtonDidTap: (() -> Void)

  init(
    connectedDeviceName: String?,
    reconnectingDeviceName: String?,
    @ViewBuilder indicatorMenuContent: @escaping () -> IndicatorMenuContent,
    backButtonDidTap: (() -> Void)? = nil,
    connectedWithButtonDidTap: @escaping () -> Void
  ) {
    self.connectedDeviceName = connectedDeviceName
    self.reconnectingDeviceName = reconnectingDeviceName
    self.indicatorMenuContent = indicatorMenuContent
    self.connectedWithButtonDidTap = connectedWithButtonDidTap
  }
}

extension TopToolBarView: View {
  var body: some View {
    ConnectedWithView(
      connectedDeviceName: connectedDeviceName ?? reconnectingDeviceName,
      menuContent: indicatorMenuContent
    ) {
      connectedWithButtonDidTap()
    }
  }

  var placeholderEmptyView: some View {
    Rectangle()
      .foregroundStyle(.clear)
      .frame(width: 44, height: 44)
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()

    VStack {
      TopToolBarView(connectedDeviceName: "임영택의 iPhone 16", reconnectingDeviceName: nil) {
        //
      } connectedWithButtonDidTap: {
        //
      }

      TopToolBarView(connectedDeviceName: "임영택의 iPhone 16", reconnectingDeviceName: nil) {
        //
      } backButtonDidTap: {
        //
      } connectedWithButtonDidTap: {
        //
      }
    }
  }
}
