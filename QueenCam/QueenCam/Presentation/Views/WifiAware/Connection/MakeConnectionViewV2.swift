//
//  MakeConnectionViewV2.swift
//  QueenCam
//
//  Created by 임영택 on 9/6/26.
//

import SwiftUI
import WiFiAware

struct MakeConnectionViewV2 {
  @Environment(\.dismiss) private var dismiss

  let role: Role
  let networkState: NetworkState?
  let selectedPairedDevice: WAPairedDevice?
  let pairedDevices: [ExtendedWAPairedDevice]
  let isConnected: Bool
  let pairingButtonContent: AnyView?
  var lastConnectionError: Error?
  let errorWasConsumeByUser: () -> Void
  let changeRoleButtonDidTap: () -> Void
  let connectButtonDidTap: (WAPairedDevice) -> Void
  let stopConnectingButtonDidTap: () -> Void

  @State var isShowingPairingHelp = false

  let backgroundColor = Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
  let maximumContentWidth: CGFloat = 560

  init(
    role: Role,
    networkState: NetworkState?,
    selectedPairedDevice: WAPairedDevice?,
    pairedDevices: [ExtendedWAPairedDevice],
    isConnected: Bool,
    pairingButtonContent: AnyView? = nil,
    lastConnectionError: Error? = nil,
    errorWasConsumeByUser: @escaping () -> Void,
    changeRoleButtonDidTap: @escaping () -> Void,
    connectButtonDidTap: @escaping (WAPairedDevice) -> Void,
    stopConnectingButtonDidTap: @escaping () -> Void
  ) {
    self.role = role
    self.networkState = networkState
    self.selectedPairedDevice = selectedPairedDevice
    self.pairedDevices = pairedDevices
    self.isConnected = isConnected
    self.pairingButtonContent = pairingButtonContent
    self.lastConnectionError = lastConnectionError
    self.errorWasConsumeByUser = errorWasConsumeByUser
    self.changeRoleButtonDidTap = changeRoleButtonDidTap
    self.connectButtonDidTap = connectButtonDidTap
    self.stopConnectingButtonDidTap = stopConnectingButtonDidTap
  }

  var isPairing: Bool {
    networkState == .host(.publishing)
      || networkState == .viewer(.browsing)
      || networkState == .viewer(.connecting)
  }

  var contentMaxWidth: CGFloat {
    if DynamicModelUtils.isiPad {
      return maximumContentWidth
    }
    return min(UIScreen.main.bounds.width, maximumContentWidth)
  }

  var connectionTitle: LocalizedStringKey {
    pairedDevices.isEmpty ? "등록된 기기가 없습니다" : "친구의 기기와 연결해주세요"
  }

  var connectionSubtitle: LocalizedStringKey {
    pairedDevices.isEmpty
      ? "페어링을 통해 기기를 등록해야 연결할 수 있어요.\n먼저 친구의 기기와 페어링해 주세요."
      : "등록된 기기와는 바로 연결할 수 있어요.\n목록에 없는 기기와는 페어링을 먼저 진행해주세요."
  }

  var connectionStatusOverlayState: ConnectionStatusOverlayView.State? {
    if lastConnectionError != nil {
      return .failed
    }

    guard isPairing, let selectedPairedDevice else {
      return nil
    }

    return .connecting(
      deviceName: selectedPairedDevice.pairingInfo?.pairingName ?? selectedPairedDevice.name ?? ""
    )
  }
}

extension MakeConnectionViewV2: View {
  var body: some View {
    ZStack {
      backgroundColor
        .ignoresSafeArea()

      VStack(spacing: 0) {
        navigationControls
          .padding(.top, 16)

        Spacer()
          .frame(height: 36)

        roleControls

        Spacer()
          .frame(height: 12)

        connectionHeader

        Spacer()
          .frame(height: 24)

        pairedDeviceList
      }
      .frame(maxWidth: contentMaxWidth)
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      bottomControls
        .frame(maxWidth: contentMaxWidth)
    }
    .toolbar(.hidden, for: .navigationBar)
    .overlay {
      if let connectionStatusOverlayState {
        ConnectionStatusOverlayView(
          state: connectionStatusOverlayState,
          actionButtonDidTap: connectionStatusActionButtonDidTap
        )
      }
    }
    .sheet(isPresented: $isShowingPairingHelp) {
      PairingGuideSheetView(role: role) {
        isShowingPairingHelp = false
      }
      .pairingSheetPresentationStyle()
    }
  }
}

extension MakeConnectionViewV2 {
  func connectionStatusActionButtonDidTap() {
    if lastConnectionError != nil {
      errorWasConsumeByUser()
    } else {
      stopConnectingButtonDidTap()
    }
  }

  func dismissButton(systemName: String, identifier: String) -> some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: systemName)
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(.offWhite)
        .frame(width: 45, height: 45)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("닫기")
    .accessibilityIdentifier(identifier)
  }
}

#Preview("촬영 · 기기 없음") {
  MakeConnectionViewV2(
    role: .photographer,
    networkState: .host(.stopped),
    selectedPairedDevice: nil,
    pairedDevices: [],
    isConnected: false,
    errorWasConsumeByUser: { },
    changeRoleButtonDidTap: { },
    connectButtonDidTap: { _ in },
    stopConnectingButtonDidTap: { }
  )
}
