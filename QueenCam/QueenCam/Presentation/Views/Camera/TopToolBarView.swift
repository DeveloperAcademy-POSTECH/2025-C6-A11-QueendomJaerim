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

  /// 뒤로 가기 버튼 액션. nil이면 뒤로가기 버튼 숨김
  let backButtonDidTap: (() -> Void)?

  /// 현재 연결 기기 버튼 액션
  let connectedWithButtonDidTap: (() -> Void)

  private let minimumSpacing: CGFloat = 16
  private let backButtonSymbolName: String = "chevron.left"

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
    self.backButtonDidTap = backButtonDidTap
    self.connectedWithButtonDidTap = connectedWithButtonDidTap
  }
}

extension TopToolBarView: View {
  var body: some View {
    HStack(spacing: 0) {
      if let backButtonDidTap {
        ToolBarButton(symbolName: backButtonSymbolName) {
          backButtonDidTap()
        }
      } else {
        placeholderEmptyView
      }

      Spacer(minLength: minimumSpacing)

      ConnectedWithView(
        connectedDeviceName: connectedDeviceName ?? reconnectingDeviceName,
        menuContent: indicatorMenuContent
      ) {
        connectedWithButtonDidTap()
      }

      Spacer(minLength: minimumSpacing)

      placeholderEmptyView
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
