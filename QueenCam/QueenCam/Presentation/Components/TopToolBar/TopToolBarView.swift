//
//  TopToolBarView.swift
//  QueenCam
//
//  Created by 임영택 on 10/30/25.
//

import SwiftUI

/// Top Tool Bar
struct TopToolBarView<MenuContent: View>: View {
  /// 연결 여부
  let isConnected: Bool
  
  /// 연결된 디바이스 이름
  let connectedDeviceName: String?

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
    isConnected: Bool,
    connectedDeviceName: String?,
    @ViewBuilder menuContent: @escaping () -> MenuContent,
    backButtonDidTap: (() -> Void)? = nil,
    connectedWithButtonDidTap: @escaping () -> Void
  ) {
    self.isConnected = isConnected
    self.connectedDeviceName = connectedDeviceName
    self.backButtonDidTap = backButtonDidTap
    self.menuContent = menuContent
    self.connectedWithButtonDidTap = connectedWithButtonDidTap
  }

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
        isConnected: isConnected,
        connectedDeviceName: connectedDeviceName
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
    TopToolBarView(isConnected: true, connectedDeviceName: "임영폰") {
      Button("기능 1") {}
      Button("기능 2") {}
      Button("기능 3") {}

      Divider()

      Button("신고하기", systemImage: "exclamationmark.triangle") {}
    } connectedWithButtonDidTap: {
      //
    }

    TopToolBarView(isConnected: true, connectedDeviceName: "임영택임영택임영택임영택의 iPhone") {
      Button("기능 1") {}
      Button("기능 2") {}
      Button("기능 3") {}

      Divider()

      Button("신고하기", systemImage: "exclamationmark.triangle") {}
    } connectedWithButtonDidTap: {
      //
    }

    TopToolBarView(isConnected: true, connectedDeviceName: "임영택임영택임영택임영택의 iPhone") {
      //
    } backButtonDidTap: {
      //
    } connectedWithButtonDidTap: {
      //
    }

    TopToolBarView(isConnected: false, connectedDeviceName: nil) {
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
