//
//  ConnectionView.swift
//  QueenCam
//
//  Created by 임영택 on 10/4/25.
//

import DeviceDiscoveryUI
import SwiftUI
import WiFiAware

struct ConnectionView: View {
  @State private var router = NavigationRouter()
  @Environment(\.dismiss) var dismiss
  var viewModel: ConnectionViewModel
  var previewStreamingViewModel: PreviewModel

  @State private var activeRole: Role?
}

extension ConnectionView {
  var body: some View {
    NavigationStack(path: $router.path) {
      SelectRoleView(
        selectedRole: activeRole,
        didRoleSelect: { role in
          activeRole = role
        },
        didRoleSubmit: { role in
          viewModel.selectRole(for: role)
          router.push(.connectionGuide)
        }
      )
      .navigationDestination(for: Route.self) { route in
        ConnectionNavigatedView(route: route, connectionViewModel: viewModel)
      }
    }
    .task {
      await viewModel.viewDidAppearTask()
    }
    .onDisappear {
      viewModel.connectionViewDisappear()
    }
    .onChange(of: viewModel.connections) { _, newValue in  // 연결 완료
      
      if !newValue.isEmpty {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          dismiss()
        }
      }
    }
    .environment(\.router, router)
  }
}

#Preview {
  struct ConnectionViewPeviewContainer: View {
    @State var viewModel: ConnectionViewModel = .init(
      networkService: NetworkService(),
      notificationService: NotificationService()
    )

    @State var previewModel: PreviewModel = .init(
      previewCaptureService: PreviewCaptureService(),
      networkService: NetworkService()
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
