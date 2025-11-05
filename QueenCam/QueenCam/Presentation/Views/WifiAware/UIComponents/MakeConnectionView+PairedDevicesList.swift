//
//  MakeConnectionView+PairedDevicesList.swift
//  QueenCam
//
//  Created by 임영택 on 11/5/25.
//

import SwiftUI
import WiFiAware

extension MakeConnectionView {
  struct PairedDevicesList {
    let pairedDevices: [WAPairedDevice]
    /// 특정 디바이스에 대해 페어링 중인지 판단하는 클로져. true를 반환하면 프로그레스 뷰를 해당 디바이스 옆에 띄운다.
    let isPairing: (_ device: WAPairedDevice) -> Bool
    let connectButtonDidTap: (WAPairedDevice) -> Void

    // MARK: Colors
    let titleLabelForegroundColor = Color(red: 0xD4 / 255, green: 0xD4 / 255, blue: 0xD4 / 255)
    let dividerColor = Color(red: 0xEB / 25, green: 0xEB / 25, blue: 0xEB / 25)
  }
}

extension MakeConnectionView.PairedDevicesList: View {
  var body: some View {
    VStack(spacing: 0) {
      // 타이틀
      HStack {
        Text("찾아낸 기기")
          .foregroundStyle(titleLabelForegroundColor)
          .font(.pretendard(.medium, size: 15))

        Spacer()
      }
      .padding(.horizontal, 8)

      Rectangle()
        .foregroundStyle(dividerColor)
        .frame(height: 0.5)
        .padding(.top, 8.5)
        .padding(.bottom, 16)

      // 리스트
      VStack(spacing: 8) {
        ForEach(pairedDevices) { device in
          HStack(alignment: .center) {
            Text(device.pairingInfo?.pairingName ?? "알 수 없는 이름")
              .font(.pretendard(.medium, size: 18))
              .foregroundStyle(.offWhite)

            Spacer()

            // 프로그레스 뷰 + 연결 버튼
            if isPairing(device) {
              ProgressView()
                .tint(.offWhite)
                .frame(width: 42, height: 42)
            } else {
              Button {
                connectButtonDidTap(device)
              } label: {
                HStack(alignment: .center, spacing: 4) {
                  Text("연결")
                    .font(.pretendard(.medium, size: 14))
                }
                .foregroundStyle(.offWhite)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
              }
              .glassEffect(.regular)
            }
          }
        }
      }
    }
  }
}
