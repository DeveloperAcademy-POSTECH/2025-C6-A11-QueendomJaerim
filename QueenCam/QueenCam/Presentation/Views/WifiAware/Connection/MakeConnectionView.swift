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
  let isConnected: Bool
  var lastConnectionError: Error?
  let errorWasConsumeByUser: () -> Void
  let changeRoleButtonDidTap: () -> Void
  let connectButtonDidTap: (WAPairedDevice) -> Void
  
  @State private var errorAlertShowing: Bool = false

  private var myDeviceName: String {
    UIDevice.current.name
  }

  private var isPairing: Bool {
    networkState == .host(.publishing)
      || networkState == .viewer(.browsing)
      || networkState == .viewer(.connecting)
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
      .alert(
        "연결에 실패했습니다",
        isPresented: .init(
          get: {
            lastConnectionError != nil
          },
          set: { newValue in
            if !newValue {
              errorWasConsumeByUser()
            }
          }
        ),
        actions: {
          Button(role: .confirm) {
            openSetting()
          } label: {
            Text("설정으로 가기")
          }

          Button(role: .cancel) {
          } label: {
            Text("확인")
          }
        },
        message: {
          Text("Wi-Fi 기능을 활성화하고 다시 시도해주세요.")
        }
      )
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
          isPairing: isPairing,
          isConnected: isConnected,
          selectedDevice: selectedPairedDevice,
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

extension MakeConnectionView {
  private func openSetting() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}

#Preview {
  MakeConnectionView(
    role: .photographer,
    networkState: .host(.stopped),
    selectedPairedDevice: nil,
    pairedDevices: [],
    isConnected: false,
    lastConnectionError: nil,
    errorWasConsumeByUser: {},
    changeRoleButtonDidTap: {},
    connectButtonDidTap: { _ in }
  )
}
