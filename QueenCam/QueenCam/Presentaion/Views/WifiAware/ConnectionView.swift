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
  let viewModel: WifiAwareViewModel
}

extension ConnectionView {
  var body: some View {
    Group {
      if let role = viewModel.role {
        VStack {
          Button {
            viewModel.role = nil
          } label: {
            Text("촬영 모드 바꾸기")
              .foregroundStyle(.black)
              .padding(10)
              .background {
                RoundedRectangle(cornerRadius: 8)
                  .foregroundStyle(.gray)
              }
          }

          if !viewModel.pairedDevices.isEmpty
              && (viewModel.networkState == .host(.stopped) || viewModel.networkState == .viewer(.stopped)) {
            List(viewModel.pairedDevices) { device in
              Text(device.pairingInfo?.pairingName ?? "알 수 없는 이름")
                .onTapGesture {
                  viewModel.connectButtonTapped(for: device)
                }
            }
            .listStyle(.grouped)
          } else {
            Spacer()
          }
          
          if (viewModel.networkState == .host(.publishing)
              || viewModel.networkState == .viewer(.browsing)
              || viewModel.networkState == .viewer(.connecting))
              && viewModel.connections.isEmpty {
            Text("두 기기를 연결하고 있어요")
          }
          
          if !viewModel.connections.isEmpty {
            Text("연결이 완료되었어요")
          }

          if role == .photographer {
            DevicePairingView(.wifiAware(.connecting(to: .previewService, from: .userSpecifiedDevices))) {
              HStack {
                Image(systemName: "video.bubble.fill")

                Text("다른 기기와 페어링하기")
              }
            } fallback: {
              Image(systemName: "xmark.circle")
              Text("Unavailable")
            }
          } else {
            DevicePicker(.wifiAware(.connecting(to: .userSpecifiedDevices, from: .previewService))) { endpoint in
              viewModel.didEndpointSelect(endpoint: endpoint)
            } label: {
              HStack {
                Image(systemName: "eye")

                Text("다른 기기와 페어링하기")
              }
            } fallback: {
              Image(systemName: "xmark.circle")
              Text("Unavailable")
            }
          }

          Spacer()
        }
      } else {
        VStack {
          Text("역할을 선택해주세요")
            .fontWeight(.bold)

          Text("서로 다른 역할의 기기끼리만 연결할 수 있어요")

          Spacer()
            .frame(height: 60)

          HStack {
            RoleSelectButton(guideText: "이 기기로 찍을게요", roleText: "촬영") {
              viewModel.role = .photographer
            }

            RoleSelectButton(guideText: "이 기기로 볼게요", roleText: "모델") {
              viewModel.role = .model
            }
          }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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

    var body: some View {
      ConnectionView(viewModel: viewModel)
        .onAppear {
          viewModel.role = nil
        }
    }
  }

  return ConnectionViewPeviewContainer()
}
