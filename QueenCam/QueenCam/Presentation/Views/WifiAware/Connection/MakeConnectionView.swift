//
//  MakeConnectionView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import DeviceDiscoveryUI
import OSLog
import SwiftUI
import WiFiAware

struct MakeConnectionView {
  @Environment(\.dismiss) private var dismiss
  
  let role: Role
  let networkState: NetworkState?
  let selectedPairedDevice: WAPairedDevice?
  let pairedDevices: [WAPairedDevice]
  let changeRoleButtonDidTap: () -> Void
  let connectButtonDidTap: (WAPairedDevice) -> Void

  private var myDeviceName: String {
    UIDevice.current.name
  }

  // MARK: Colors
  let photographerTheme = Color(red: 0x14 / 255, green: 0xB1 / 255, blue: 0xBB / 255)
  let modelTheme = Color(red: 0xD8 / 255, green: 0xEB / 255, blue: 0x05 / 255)
}

extension MakeConnectionView: View {
  var body: some View {
    NavigationStack {
      ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 0) {
          ToolBar(role: role, changeRoleButtonDidTap: changeRoleButtonDidTap)

          Spacer()
            .frame(height: 20)

          // MARK: - 주변 기기 찾기 버튼
          DeviceDiscoveryButton(role: role, photographerTheme: photographerTheme, modelTheme: modelTheme)

          Spacer()
            .frame(height: 40)

          // MARK: - 찾아낸 기기 리스트
          PairedDevicesList(
            pairedDevices: pairedDevices,
            isPairing: { device in
              selectedPairedDevice == device
                && (networkState == .host(.publishing)
                  || networkState == .viewer(.browsing)
                  || networkState == .viewer(.connecting)
                  || networkState == .viewer(.connected))
            },
            connectButtonDidTap: connectButtonDidTap
          )

          Spacer()
        }
        .padding(16)
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button("닫기", systemImage: "chevron.left") {
          dismiss()
        }
      }

      ToolbarItem(placement: .principal) {
        Text("기기 연결하기")
          .foregroundStyle(.offWhite)
      }

      ToolbarItem(placement: .topBarTrailing) {
        Button("가이드", systemImage: "questionmark.circle") {
          //
        }
      }
    }
  }
}

extension MakeConnectionView {
  struct DeviceDiscoveryButton: View {
    let role: Role

    // MARK: Colors
    let photographerTheme: Color
    let modelTheme: Color

    // MARK: Logger
    private let logger = Logger(
      subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam",
      category: "MakeConnectionView+DevicePicker"
    )

    var body: some View {
      if role == .photographer {
        DevicePairingView(.wifiAware(.connecting(to: .previewService, from: .userSpecifiedDevices))) {
          DeviceDiscoveryButtonLabelView(themeColor: photographerTheme)
        } fallback: {
          Image(systemName: "xmark.circle")
          Text("Unavailable")
        }
      } else {
        DevicePicker(.wifiAware(.connecting(to: .userSpecifiedDevices, from: .previewService))) { endpoint in
          logger.info("publisher did select endpoint - \(endpoint)")
        } label: {
          DeviceDiscoveryButtonLabelView(themeColor: modelTheme)
        } fallback: {
          Image(systemName: "xmark.circle")
          Text("Unavailable")
        }
      }
    }
  }
}

#Preview {
  MakeConnectionView(
    role: .photographer,
    networkState: .host(.stopped),
    selectedPairedDevice: nil,
    pairedDevices: [],
    changeRoleButtonDidTap: {},
    connectButtonDidTap: { _ in }
  )
}
