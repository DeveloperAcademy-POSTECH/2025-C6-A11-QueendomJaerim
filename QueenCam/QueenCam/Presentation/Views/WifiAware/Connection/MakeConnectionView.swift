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

  // MARK: State
  @State private var isShowingParingGuide: Bool = false
}

extension MakeConnectionView: View {
  var body: some View {
    NavigationStack {
      ZStack {
        Color.black.ignoresSafeArea()

        if isShowingParingGuide {
          pairingGuideView
        } else {
          makeConnectionControls
        }
      }
    }
  }
}

extension MakeConnectionView {
  var pairingGuideView: some View {
    ConnectionGuideView(
      role: role,
      didGuideComplete: {
        isShowingParingGuide = false
      },
      backButtonDidTap: {
        isShowingParingGuide = false
      }
    )
  }
}

// MARK: 연결 진행 페이지
extension MakeConnectionView {
  var makeConnectionControls: some View {
    NavigationStack {
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
        .frame(maxHeight: .infinity, alignment: .top)
      }
      .padding(.horizontal, 16)
      .ignoresSafeArea(edges: .bottom)
    }
    .navigationBarTitleDisplayMode(.inline)  // LargeTitle 때문에 레이아웃 깨지는 문제 수정
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
          isShowingParingGuide = true
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
