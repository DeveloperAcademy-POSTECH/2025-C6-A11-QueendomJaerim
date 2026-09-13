//
//  ConnectionView.swift
//  QueenCam
//
//  Created by 임영택 on 10/4/25.
//

import DeviceDiscoveryUI
import SwiftUI
import WiFiAware

struct ConnectionView {
  @Environment(\.dismiss) var dismiss
  var connectionViewModel: ConnectionViewModel
  var guideViewModel: ConnectionGuideViewModel
  var previewStreamingViewModel: PreviewModel

  /// 사용자가 선택중인 역할 (아직 확정된 것은 아님)
  @State private var activeRole: Role?

  /// 하위 뷰로 전파할 연결 여부
  @State private var isConnected: Bool = false
}

extension ConnectionView: View {
  var body: some View {
    NavigationStack {
      if connectionViewModel.role != nil {
        makeConnectionView
      } else {
        selectRoleView
      }
    }
    .trackScreen(.connectionSheet, Self.self)
    .onAppear {
      connectionViewModel.connectionViewAppear()
    }
    .onDisappear {
      connectionViewModel.connectionViewDisappear()
    }
    .onChange(of: connectionViewModel.connections) { _, newValue in  // 연결 완료
      if !newValue.isEmpty {
        isConnected = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
          dismiss()
        }
      }
    }
  }
}

extension ConnectionView {
  // MARK: Subviews

  @ViewBuilder
  var makeConnectionView: some View {
    if let selectedRole = connectionViewModel.role {
      MakeConnectionViewV2(
        role: selectedRole,
        networkState: connectionViewModel.networkState,
        selectedPairedDevice: connectionViewModel.selectedPairedDevice,
        pairedDevices: connectionViewModel.pairedDevices,
        isConnected: isConnected,
        lastConnectionError: connectionViewModel.connectionError,
        errorWasConsumeByUser: {
          connectionViewModel.errorConfirmedByUser()
        },
        changeRoleButtonDidTap: {
          connectionViewModel.selectRole(for: selectedRole.counterpart)
        },
        connectButtonDidTap: { device in
          connectionViewModel.connectButtonDidTap(for: device)
        },
        stopConnectingButtonDidTap: {
          connectionViewModel.stopConnectingButtonDidTap()
        }
      )
    } else {  // should not reach
      Text("역할이 선택되지 않았습니다")
    }
  }

  var selectRoleView: some View {
    SelectRoleViewV2(
      selectedRole: activeRole,
      didRoleSelect: { role in
        if role == activeRole {
          activeRole = nil
        } else {
          activeRole = role
        }
      },
      didRoleSubmit: {
        guard let activeRole else { return }
        connectionViewModel.selectRole(for: activeRole)
      }
    )
  }
}

#Preview {
  struct ConnectionViewPeviewContainer: View {
    @State var viewModel: ConnectionViewModel = .init(
      networkService: NetworkService(),
      notificationService: NotificationService(),
      pairedDeviceRegistry: WAPairedDeviceRegistry.inMemory()
    )

    @State var connectionGuideViewModel: ConnectionGuideViewModel = .init(
      onboardingSettingService: OnboardingSettingsService()
    )

    @State var previewModel: PreviewModel = .init(
      previewCaptureService: PreviewCaptureService(),
      networkService: NetworkService()
    )

    var body: some View {
      ConnectionView(
        connectionViewModel: viewModel,
        guideViewModel: connectionGuideViewModel,
        previewStreamingViewModel: previewModel
      )
      .onAppear {
        viewModel.selectRole(for: nil)
      }
    }
  }

  return ConnectionViewPeviewContainer()
}
