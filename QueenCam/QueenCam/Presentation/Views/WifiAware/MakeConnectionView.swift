//
//  MakeConnectionView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import DeviceDiscoveryUI
import SwiftUI
import WiFiAware

struct MakeConnectionView: View {
  let role: Role?

  let pairedDevices: [WAPairedDevice]
  let networkState: NetworkState?
  let connections: [WAPairedDevice: ConnectionDetail]

  let changeRoleButtonDidTap: () -> Void
  let connectButtonDidTap: (WAPairedDevice) -> Void
  let publisherDidSelectEndpoint: (WAEndpoint) -> Void

  var body: some View {
    VStack {
      Button {
        changeRoleButtonDidTap()
      } label: {
        Text("촬영 모드 바꾸기")
          .foregroundStyle(.black)
          .padding(10)
          .background {
            RoundedRectangle(cornerRadius: 8)
              .foregroundStyle(.gray)
          }
      }

      if !pairedDevices.isEmpty
        && (networkState == .host(.stopped) || networkState == .viewer(.stopped))
      {
        List(pairedDevices) { device in
          Text(device.pairingInfo?.pairingName ?? "알 수 없는 이름")
            .onTapGesture {
              connectButtonDidTap(device)
            }
        }
        .listStyle(.grouped)
      } else {
        Spacer()
      }

      if (networkState == .host(.publishing)
        || networkState == .viewer(.browsing)
        || networkState == .viewer(.connecting))
        && connections.isEmpty
      {
        Text("두 기기를 연결하고 있어요")
      }

      if !connections.isEmpty {
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
          publisherDidSelectEndpoint(endpoint)
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
  }
}
