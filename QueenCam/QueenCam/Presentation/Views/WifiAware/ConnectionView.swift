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
  @Environment(\.router) private var router
  var viewModel: WifiAwareViewModel
  var previewStreamingViewModel: PreviewModel
}

extension ConnectionView {
  var body: some View {
    Group {
      if viewModel.role != nil {
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
      } else {
        SelectRoleView { role in
          viewModel.selectRole(for: role)
        }
      }
    }
    .task {
      await viewModel.viewDidAppearTask()
    }
    .onDisappear {
      viewModel.connectionViewDisappear()
    }
    .onChange(of: viewModel.connections) { _, newValue in
      if !newValue.isEmpty {
        if viewModel.role == .photographer {
          previewStreamingViewModel.startCapture()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          router.reset()
        }
      }
    }
  }
}

struct RoleSelectButton: View {
  let guideText: String
  let roleText: String
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
    @State var viewModel: WifiAwareViewModel = .init(
      networkService: NetworkService()
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
