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
  var viewModel: ConnectionViewModel
  var previewStreamingViewModel: PreviewModel

  /// 사용자가 선택중인 역할 (아직 확정된 것은 아님)
  @State private var activeRole: Role?

  /// 가이드를 보여줘야하는지 여부
  @State private var shouldGuideShow: Bool = false

  /// 하위 뷰로 전파할 연결 여부
  @State private var isConnected: Bool = false
}

extension ConnectionView: View {
  var body: some View {
    NavigationStack {
      if viewModel.role != nil {
        makeConnectionView
      } else {
        if shouldGuideShow && activeRole != nil {
          connectionGuideView
        } else {
          selectRoleView
        }
      }
    }
    .task {
      await viewModel.viewDidAppearTask()
    }
    .onAppear {
      viewModel.connectionViewAppear()
    }
    .onDisappear {
      viewModel.connectionViewDisappear()
    }
    .onChange(of: viewModel.connections) { _, newValue in  // 연결 완료
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
    if let selectedRole = viewModel.role {
      MakeConnectionView(
        role: selectedRole,
        networkState: viewModel.networkState,
        selectedPairedDevice: viewModel.selectedPairedDevice,
        pairedDevices: viewModel.pairedDevices,
        isConnected: isConnected,
        lastConnectionError: viewModel.connectionError,
        errorWasConsumeByUser: {
          viewModel.errorConfirmedByUser()
        },
        changeRoleButtonDidTap: {
          viewModel.selectRole(for: selectedRole.counterpart)
        },
        connectButtonDidTap: { device in
          viewModel.connectButtonDidTap(for: device)
        }
      )
    } else {  // should not reach
      Text("역할이 선택되지 않았습니다")
    }
  }

  @ViewBuilder
  var connectionGuideView: some View {
    if let activeRole {
      ConnectionGuideView(
        role: activeRole,
        didGuideComplete: {
          shouldGuideShow = false
          viewModel.selectRole(for: activeRole)  // 가이드가 끝나면 역할 확정
        },
        backButtonDidTap: {
          shouldGuideShow = false
          viewModel.selectRole(for: nil)
        }
      )
    } else {
      Text("역할이 선택되지 않았습니다")
    }
  }

  var selectRoleView: some View {
    SelectRoleView(
      selectedRole: activeRole,
      didRoleSelect: { role in
        if role == activeRole {
          activeRole = nil
        } else {
          activeRole = role
        }
      },
      didRoleSubmit: {
        shouldGuideShow = true  // 역할 선택 버튼을 누르면 가이드를 보여줌
      }
    )
  }
}

#Preview {
  struct ConnectionViewPeviewContainer: View {
    @State var viewModel: ConnectionViewModel = .init(
      networkService: NetworkService(waPairedDevicesRepository: WAPairedDevicesRepository()),
      notificationService: NotificationService(),
      waPairedDevicesRepository: WAPairedDevicesRepository()
    )

    @State var previewModel: PreviewModel = .init(
      previewCaptureService: PreviewCaptureService(),
      networkService: NetworkService(waPairedDevicesRepository: WAPairedDevicesRepository())
    )

    var body: some View {
      ConnectionView(viewModel: viewModel, previewStreamingViewModel: previewModel)
        .onAppear {
          viewModel.selectRole(for: nil)
        }
    }
  }

  return ConnectionViewPeviewContainer()
}
