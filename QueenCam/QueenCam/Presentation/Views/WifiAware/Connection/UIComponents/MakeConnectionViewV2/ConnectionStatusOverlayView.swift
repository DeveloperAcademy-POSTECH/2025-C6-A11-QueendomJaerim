//
//  ConnectionStatusOverlayView.swift
//  QueenCam
//
//  Created by 임영택 on 9/12/26.
//

import SwiftUI

struct ConnectionStatusOverlayView: View {
  enum State: Equatable {
    case connecting(deviceName: String)
    case failed
  }

  let state: State
  let actionButtonDidTap: () -> Void

  private let modalWidth: CGFloat = 311
  private let connectingModalHeight: CGFloat = 278
  private let failedModalHeight: CGFloat = 166
  private let connectingContentSpacing: CGFloat = 35
  private let failedContentSpacing: CGFloat = 23
  private let progressIndicatorSize: CGFloat = 30
  private let progressIndicatorScale: CGFloat = 1.5
  private let buttonBackgroundColor = Color(
    red: 51 / 255,
    green: 51 / 255,
    blue: 51 / 255
  )

  var body: some View {
    ZStack {
      Color.originalBlack
        .opacity(0.8)
        .ignoresSafeArea()
        .accessibilityIdentifier("connection-status-overlay.dimmed-background")

      modalContent
        .frame(width: modalWidth)
        .frame(minHeight: modalMinimumHeight)
        .background(Color.gray900, in: RoundedRectangle(cornerRadius: 32))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("connection-status-overlay.modal")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var modalMinimumHeight: CGFloat {
    switch state {
    case .connecting:
      connectingModalHeight
    case .failed:
      failedModalHeight
    }
  }

  @ViewBuilder
  private var modalContent: some View {
    switch state {
    case .connecting(let deviceName):
      connectingContent(deviceName: deviceName)
    case .failed:
      failedContent
    }
  }

  private func connectingContent(deviceName: String) -> some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        Text("‘\(deviceName)’(와)과\n연결 중이에요.")
          .typo(.sb17)
          .foregroundStyle(.systemWhite)
          .accessibilityIdentifier("connection-status-overlay.title")

        Text("상대방 기기에서도 '연결' 버튼을 눌렀는지 확인해 주세요.")
          .typo(.m14)
          .foregroundStyle(.gray400)
          .accessibilityIdentifier("connection-status-overlay.message")
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 20)
      .padding(.horizontal, 24)

      Spacer()
        .frame(height: connectingContentSpacing)

      ProgressView()
        .controlSize(.regular)
        .scaleEffect(progressIndicatorScale)
        .frame(width: progressIndicatorSize, height: progressIndicatorSize)
        .tint(.gray400)
        .accessibilityLabel("연결 중")
        .accessibilityIdentifier("connection-status-overlay.progress")

      Spacer()
        .frame(height: connectingContentSpacing)

      actionButton(title: "연결 중단하기", foregroundColor: .gray600)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
  }

  private var failedContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 14) {
        Text("연결에 실패했어요.")
          .typo(.sb17)
          .foregroundStyle(.systemWhite)
          .accessibilityIdentifier("connection-status-overlay.title")

        Text("상대방과 함께 다시 시도해 주세요.")
          .typo(.m14)
          .foregroundStyle(.gray400)
          .accessibilityIdentifier("connection-status-overlay.message")
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 20)
      .padding(.horizontal, 24)

      Spacer()
        .frame(height: failedContentSpacing)

      actionButton(title: "닫기", foregroundColor: .gray400)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
  }

  private func actionButton(
    title: LocalizedStringKey,
    foregroundColor: Color
  ) -> some View {
    Button(action: actionButtonDidTap) {
      Text(title)
        .typo(.sb16)
        .foregroundStyle(foregroundColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(buttonBackgroundColor, in: Capsule())
    }
    .buttonStyle(.plain)
    .frame(height: 52)
    .accessibilityIdentifier("connection-status-overlay.action-button")
  }
}

#Preview("연결 중") {
  ConnectionStatusOverlayView(
    state: .connecting(deviceName: "임영택의 iPhone 16")
  ) { }
  .background(Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255))
}

#Preview("연결 실패") {
  ConnectionStatusOverlayView(
    state: .failed
  ) { }
  .background(Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255))
}
