//
//  MakeConnectionView+DeviceDiscoveryButton.swift
//  QueenCam
//
//  Created by 임영택 on 11/5/25.
//

import DeviceDiscoveryUI
import SwiftUI
import WiFiAware

extension MakeConnectionView {
  struct DeviceDiscoveryButton: View {
    let role: Role

    // MARK: Colors
    let photographerTheme: Color
    let modelTheme: Color

    // MARK: Logger
    private let devicePickerLogger = QueenLogger(category: "MakeConnectionView+DevicePicker")

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
          devicePickerLogger.info("publisher did select endpoint - \(endpoint)")
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

extension MakeConnectionView {
  struct DeviceDiscoveryButtonLabelView: View {
    let themeColor: Color

    var body: some View {
      HStack {
        Text("주변 기기 찾기")
          .font(.pretendard(.medium, size: 18))
          .foregroundStyle(.white)
          .background(
            Capsule()
              .foregroundStyle(.clear)
          )

        Spacer()

        RoundedRectangle(cornerRadius: 16)
          .foregroundStyle(themeColor)
          .frame(width: 41, height: 33)
          .overlay {
            Image(systemName: "arrow.right")
              .font(.system(size: 16))
              .foregroundStyle(.gray900)
              .padding()
          }
      }
      .padding(.leading, 24)
      .padding(.trailing, 10)
      .frame(maxWidth: .infinity, maxHeight: 53)
      .glassEffect(.regular)
    }
  }
}

#Preview {
  MakeConnectionView.DeviceDiscoveryButtonLabelView(themeColor: .photographerPrimary)
}
