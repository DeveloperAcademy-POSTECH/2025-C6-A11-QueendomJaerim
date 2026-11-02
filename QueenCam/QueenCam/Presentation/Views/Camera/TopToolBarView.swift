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

  let role: Role?

  /// nil이면 비율 버튼을 숨긴다(모델).
  let aspectRatioTitle: String?

  /// 가운데 연결 메뉴 아이템
  @ViewBuilder let indicatorMenuContent: () -> IndicatorMenuContent

  /// 현재 연결 기기 버튼 액션
  let connectedWithButtonDidTap: (() -> Void)

  let aspectRatioButtonDidTap: () -> Void

  let settingsButtonDidTap: () -> Void

  init(
    connectedDeviceName: String?,
    reconnectingDeviceName: String?,
    role: Role?,
    aspectRatioTitle: String?,
    @ViewBuilder indicatorMenuContent: @escaping () -> IndicatorMenuContent,
    backButtonDidTap: (() -> Void)? = nil,
    connectedWithButtonDidTap: @escaping () -> Void,
    aspectRatioButtonDidTap: @escaping () -> Void,
    settingsButtonDidTap: @escaping () -> Void
  ) {
    self.connectedDeviceName = connectedDeviceName
    self.reconnectingDeviceName = reconnectingDeviceName
    self.role = role
    self.aspectRatioTitle = aspectRatioTitle
    self.indicatorMenuContent = indicatorMenuContent
    self.connectedWithButtonDidTap = connectedWithButtonDidTap
    self.aspectRatioButtonDidTap = aspectRatioButtonDidTap
    self.settingsButtonDidTap = settingsButtonDidTap
  }
}

extension TopToolBarView: View {
  var body: some View {
    HStack {
      ConnectedWithView(
        connectedDeviceName: connectedDeviceName ?? reconnectingDeviceName,
        role: role,
        menuContent: indicatorMenuContent
      ) {
        connectedWithButtonDidTap()
      }

      Spacer()

      HStack(spacing: 12) {
        if let aspectRatioTitle {
          Button(action: aspectRatioButtonDidTap) {
            Text(verbatim: aspectRatioTitle)
              .typo(.r12)
              .foregroundStyle(.offWhite)
              .padding(.horizontal, 12)
              .padding(.vertical, 9)
              .glassEffect()
          }
          .accessibilityLabel("사진 비율")
        }

        Button(action: settingsButtonDidTap) {
          Image(.settings)
            .renderingMode(.template)
            .foregroundStyle(.offWhite)
            .frame(width: 22, height: 22)
            .padding(6)
            .glassEffect()
        }
        .accessibilityLabel("설정")
      }
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
      TopToolBarView(
        connectedDeviceName: "임영택의 iPhone 16",
        reconnectingDeviceName: nil,
        role: .photographer,
        aspectRatioTitle: "4:3"
      ) {
        //
      } connectedWithButtonDidTap: {
        //
      } aspectRatioButtonDidTap: {
        //
      } settingsButtonDidTap: {
        //
      }

      TopToolBarView(
        connectedDeviceName: nil,
        reconnectingDeviceName: nil,
        role: nil,
        aspectRatioTitle: "4:3"
      ) {
        //
      } connectedWithButtonDidTap: {
        //
      } aspectRatioButtonDidTap: {
        //
      } settingsButtonDidTap: {
        //
      }
    }
    .padding(.horizontal, 12)
  }
}
