//
//  TopToolBarView.swift
//  QueenCam
//
//  Created by 임영택 on 10/30/25.
//

import SwiftUI

/// Top Tool Bar
struct TopToolBarView<MenuContent: View> {
  /// 연결된 디바이스 이름 (연결이 끊어졌으면 nil)
  let connectedDeviceName: String?

  /// 재연결 중인 디바이스 이름 (연결이 끊어졌지만 재연결 중이면 nil이 아님)
  let reconnectingDeviceName: String?

  /// 컨텍스트 메뉴 아이템
  @ViewBuilder let menuContent: () -> MenuContent

  /// 뒤로 가기 버튼 액션. nil이면 뒤로가기 버튼 숨김
  let backButtonDidTap: (() -> Void)?

  /// 현재 연결 기기 버튼 액션
  let connectedWithButtonDidTap: (() -> Void)

  private let minimumSpacing: CGFloat = 16
  private let backButtonSymbolName: String = "chevron.left"
  private let contextMenuSymbolName: String = "ellipsis"

  init(
    connectedDeviceName: String?,
    reconnectingDeviceName: String?,
    @ViewBuilder menuContent: @escaping () -> MenuContent,
    backButtonDidTap: (() -> Void)? = nil,
    connectedWithButtonDidTap: @escaping () -> Void
  ) {
    self.connectedDeviceName = connectedDeviceName
    self.reconnectingDeviceName = reconnectingDeviceName
    self.backButtonDidTap = backButtonDidTap
    self.menuContent = menuContent
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
        Rectangle()
          .foregroundStyle(.clear)
          .frame(width: 44, height: 44)
      }

      Spacer(minLength: minimumSpacing)

      ConnectedWithView(
        connectedDeviceName: connectedDeviceName ?? reconnectingDeviceName
      ) {
        connectedWithButtonDidTap()
      }

      Spacer(minLength: minimumSpacing)

      ToolBarMenu(symbolName: contextMenuSymbolName, menuContent: menuContent)
    }
  }
}

#Preview {
  VStack {
    TopToolBarView(connectedDeviceName: "임영폰", reconnectingDeviceName: nil) {
      Button("기능 1") {}
      Button("기능 2") {}
      Button("기능 3") {}

      Divider()

      Button("신고하기", systemImage: "exclamationmark.triangle") {}
    } connectedWithButtonDidTap: {
      //
    }

    TopToolBarView(connectedDeviceName: "임영택임영택임영택임영택의 iPhone", reconnectingDeviceName: nil) {
      Button("기능 1") {}
      Button("기능 2") {}
      Button("기능 3") {}

      Divider()

      Button("신고하기", systemImage: "exclamationmark.triangle") {}
    } connectedWithButtonDidTap: {
      //
    }

    TopToolBarView(connectedDeviceName: nil, reconnectingDeviceName: "임영택임영택임영택임영택의 iPhone") {
      //
    } backButtonDidTap: {
      //
    } connectedWithButtonDidTap: {
      //
    }

    TopToolBarView(connectedDeviceName: nil, reconnectingDeviceName: nil) {
      //
    } backButtonDidTap: {
      //
    } connectedWithButtonDidTap: {
      //
    }
  }
  .padding(20)
  .background(.black)
}
