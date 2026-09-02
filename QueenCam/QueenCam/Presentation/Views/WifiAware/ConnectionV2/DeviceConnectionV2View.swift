import DeviceDiscoveryUI
import SwiftUI
import WiFiAware

struct DeviceConnectionV2View: View {
  let connectionViewModel: ConnectionViewModel
  let backAction: () -> Void
  let closeAction: () -> Void

  @State private var isPairingGuidePresented = false

  private var role: Role {
    connectionViewModel.role ?? .model
  }

  private var devices: [ConnectionDeviceRowState] {
    connectionViewModel.pairedDevices.map { ConnectionDeviceRowState(device: $0) }
  }

  var body: some View {
    DeviceConnectionV2Content(
      role: role,
      devices: devices,
      connectAction: { connectionViewModel.connectButtonDidTap(for: $0) },
      swapRoleAction: connectionViewModel.swapConnectionRoleButtonDidTap,
      showPairingGuideAction: { isPairingGuidePresented = true }
    ) {
      PairingLaunchButton(role: role) { endpoint in
        connectionViewModel.didEndpointSelect(endpoint: endpoint)
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button("뒤로가기", systemImage: "chevron.left", action: backAction)
          .labelStyle(.iconOnly)
          .foregroundStyle(.contentPrimary)
      }

      ToolbarItem(placement: .topBarTrailing) {
        Button("닫기", systemImage: "xmark", action: closeAction)
          .labelStyle(.iconOnly)
          .foregroundStyle(.contentPrimary)
      }
    }
    .sheet(isPresented: $isPairingGuidePresented) {
      PairingGuideV2View(role: role)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
  }
}

private struct DeviceConnectionV2Content<PairingButton: View>: View {
  let role: Role
  let devices: [ConnectionDeviceRowState]
  let connectAction: (WAPairedDevice) -> Void
  let swapRoleAction: () -> Void
  let showPairingGuideAction: () -> Void
  @ViewBuilder let pairingButton: PairingButton

  private var title: LocalizedStringKey {
    devices.isEmpty ? "등록된 기기가 없습니다" : "친구의 기기와 연결해주세요"
  }

  private var description: LocalizedStringKey {
    devices.isEmpty
      ? "페어링을 통해 기기를 등록해야 연결할 수 있어요.\n먼저 친구의 기기와 페어링해 주세요."
      : "등록된 기기와는 바로 연결할 수 있어요.\n목록에 없는 기기와는 페어링을 먼저 진행해주세요."
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 0) {
        ConnectionV2RoleBadge(
          role: role,
          showsSwapButton: true,
          swapAction: swapRoleAction
        )

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .typo(.b22)
            .foregroundStyle(.contentPrimary)

          Text(description)
            .typo(.m14Line22)
            .foregroundStyle(.gray400)
        }
        .padding(.top, 12)

        LazyVStack(spacing: 10) {
          ForEach(devices) { device in
            ConnectionDeviceRow(state: device) {
              connectAction(device.device)
            }
          }
        }
        .padding(.top, 20)
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
    }
    .scrollIndicators(.hidden)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      VStack(spacing: 8) {
        Button("페어링이 처음이라면?") {
          showPairingGuideAction()
        }
        .typo(.m14Line22)
        .foregroundStyle(.gray400)
        .underline()

        pairingButton
      }
      .padding(.horizontal, 16)
      .padding(.top, 12)
      .padding(.bottom, 26)
      .background(.ultraThinMaterial)
    }
  }
}

private struct PairingLaunchButton: View {
  let role: Role
  let endpointSelected: (WASubscriberBrowser.Endpoint) -> Void

  var body: some View {
    if role == .photographer {
      DevicePairingView(.wifiAware(.connecting(to: .previewService, from: .userSpecifiedDevices))) {
        ConnectionV2PrimaryButtonLabel(title: "새로운 기기 페어링하기", role: role, isEnabled: true)
      } fallback: {
        ConnectionV2PrimaryButtonLabel(title: "페어링을 사용할 수 없어요", role: role, isEnabled: false)
      }
    } else {
      DevicePicker(.wifiAware(.connecting(to: .userSpecifiedDevices, from: .previewService))) { endpoint in
        endpointSelected(endpoint)
      } label: {
        ConnectionV2PrimaryButtonLabel(title: "새로운 기기 페어링하기", role: role, isEnabled: true)
      } fallback: {
        ConnectionV2PrimaryButtonLabel(title: "페어링을 사용할 수 없어요", role: role, isEnabled: false)
      }
    }
  }
}

#if DEBUG
private struct DeviceConnectionV2Preview: View {
  let role: Role
  let devices: [ConnectionDeviceRowState]
  var attemptState: ConnectionAttemptState = .idle

  var body: some View {
    NavigationStack {
      DeviceConnectionV2Content(
        role: role,
        devices: devices,
        connectAction: { _ in },
        swapRoleAction: {},
        showPairingGuideAction: {}
      ) {
        ConnectionV2PrimaryButton(
          title: "새로운 기기 페어링하기",
          role: role,
          isEnabled: true
        ) {}
      }
      .background(.connectionBackground)
      .overlay {
        ConnectionAttemptOverlay(state: attemptState, stopAction: {}, closeFailureAction: {})
      }
    }
    .preferredColorScheme(.dark)
  }
}

private extension ConnectionDeviceRowState {
  static func preview(
    id: UInt64,
    name: String,
    status: DeviceConnectionHistoryStatus
  ) -> ConnectionDeviceRowState {
    let json =
      """
      {
        "id": \(id),
        "name": "\(name)",
        "pairingInfo": {
          "pairingName": "\(name)",
          "vendorName": "Apple",
          "modelName": "iPhone"
        }
      }
      """
    guard let device = try? JSONDecoder().decode(WAPairedDevice.self, from: Data(json.utf8)) else {
      fatalError("WAPairedDevice 프리뷰 fixture 디코딩에 실패했습니다")
    }
    return ConnectionDeviceRowState(id: UUID(), device: device, name: name, historyStatus: status)
  }
}

#Preview("모델 · 기기 0 · 852") {
  DeviceConnectionV2Preview(role: .model, devices: [])
    .frame(width: 393, height: 852)
}

#Preview("촬영 · 기기 1 · 876") {
  DeviceConnectionV2Preview(
    role: .photographer,
    devices: [.preview(id: 1, name: "친구의 iPhone", status: .newlyRegistered)]
  )
  .frame(width: 393, height: 876)
}

#Preview("모델 · 기기 5 · 961") {
  DeviceConnectionV2Preview(
    role: .model,
    devices: (1...5).map {
      .preview(id: UInt64($0), name: "친구의 iPhone \($0)", status: .neverConnected)
    }
  )
  .frame(width: 393, height: 961)
}

#Preview("연결 중 · 876") {
  DeviceConnectionV2Preview(
    role: .photographer,
    devices: [.preview(id: 1, name: "친구의 iPhone", status: .newlyRegistered)],
    attemptState: .connecting(deviceName: "친구의 iPhone")
  )
  .frame(width: 393, height: 876)
}

#Preview("연결 실패 · 961") {
  DeviceConnectionV2Preview(role: .model, devices: [], attemptState: .failed)
    .frame(width: 393, height: 961)
}
#endif
