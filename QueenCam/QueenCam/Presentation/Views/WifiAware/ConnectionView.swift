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
}

extension ConnectionView {
  var body: some View {
    NavigationStack(path: $router.path) {
      SelectRoleView { role in
        viewModel.selectRole(for: role)
        router.push(.makeConnection)
      }
      .navigationDestination(for: Route.self) { route in
        switch route {
        case .makeConnection:
          MakeConnectionView(
            role: viewModel.role,
            pairedDevices: viewModel.pairedDevices,
            networkState: viewModel.networkState,
            connections: viewModel.connections,
            changeRoleButtonDidTap: { viewModel.selectRole(for: nil) },
            connectButtonDidTap: { device in
              viewModel.connectButtonDidTap(for: device)
            },
            publisherDidSelectEndpoint: { endpoint in
              viewModel.didEndpointSelect(endpoint: endpoint)
            }
          )
        }
      }
    }
    .task {
      await viewModel.viewDidAppearTask()
    }
    .onDisappear {
      viewModel.connectionViewDisappear()
    }
    .onChange(of: viewModel.connections) { _, newValue in // 연결 완료
      if !newValue.isEmpty {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          dismiss()
        }
      }
    }
  }
}

struct RoleSelectButton: View {
  let guideText: LocalizedStringKey
  let roleText: LocalizedStringKey
  let action: () -> Void

  var body: some View {
    Button {
      action()
    } label: {
      RoundedRectangle(cornerRadius: 23)
        .frame(width: 171, height: 247)
        .foregroundStyle(.gray)
        .overlay {
          VStack {
            Text(guideText)

            Spacer()

            Text(roleText)
          }
          .foregroundStyle(.black)
          .padding()
        }
    }
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
