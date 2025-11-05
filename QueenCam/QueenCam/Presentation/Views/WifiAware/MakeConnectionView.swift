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

private extension Role {
  var currentModeLabel: String {
    switch self {
    case .model: "모델 모드"
    case .photographer: "작가 모드"
    }
  }
}

struct MakeConnectionView: View {
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
  let gray1 = Color(red: 0xC2 / 255, green: 0xC2 / 255, blue: 0xC2 / 255)
  let gray2 = Color(red: 0x98 / 255, green: 0x98 / 255, blue: 0x98 / 255)
  let gray3 = Color(red: 0xD4 / 255, green: 0xD4 / 255, blue: 0xD4 / 255)

  let photographerTheme = Color(red: 0x14 / 255, green: 0xB1 / 255, blue: 0xBB / 255)
  let modelTheme = Color(red: 0xD8 / 255, green: 0xEB / 255, blue: 0x05 / 255)

  let dividerColor = Color(red: 0xEB / 25, green: 0xEB / 25, blue: 0xEB / 25)

  // MARK: Logger
  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "MakeConnectionView")

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 0) {
        // MARK: - 툴바
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 8) {
            Text("다음 이름으로 보여집니다")
              .foregroundStyle(gray2)
              .font(.pretendard(.medium, size: 14))
            Text("\(myDeviceName)")
              .foregroundStyle(.offWhite)
              .font(.pretendard(.medium, size: 18))
          }

          Spacer()

          Button(action: changeRoleButtonDidTap) {
            HStack(alignment: .center, spacing: 4) {
              Text(role.currentModeLabel)
                .font(.pretendard(.medium, size: 14))

              Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.system(size: 11))
            }
            .foregroundStyle(gray1)
            .padding(.vertical, 12)
            .padding(.leading, 19)
            .padding(.trailing, 15)
          }
          .glassEffect(.regular)
        }

        Spacer()
          .frame(height: 20)

        // MARK: - 주변 기기 찾기 버튼
        if role == .photographer {
          DevicePairingView(.wifiAware(.connecting(to: .previewService, from: .userSpecifiedDevices))) {
            HStack {
              Text("주변 기기 찾기")
                .font(.pretendard(.medium, size: 18))
                .foregroundStyle(.offWhite)
                .background(
                  Capsule()
                    .foregroundStyle(.clear)
                )

              Spacer()

              RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(photographerTheme)
                .frame(width: 41, height: 33)
                .overlay {
                  Image(systemName: "arrow.right")
                    .font(.system(size: 16))
                    .foregroundStyle(.offWhite)
                    .padding()
                }
            }
            .padding(.leading, 24)
            .padding(.trailing, 10)
            .frame(maxWidth: .infinity, maxHeight: 53)
            .glassEffect(.regular)
          } fallback: {
            Image(systemName: "xmark.circle")
            Text("Unavailable")
          }
        } else {
          DevicePicker(.wifiAware(.connecting(to: .userSpecifiedDevices, from: .previewService))) { endpoint in
            logger.info("publisher did select endpoint - \(endpoint)")
          } label: {
            HStack {
              Text("주변 기기 찾기")
                .font(.pretendard(.medium, size: 18))
                .foregroundStyle(.offWhite)
                .background(
                  Capsule()
                    .foregroundStyle(.clear)
                )

              Spacer()

              RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(modelTheme)
                .frame(width: 41, height: 33)
                .overlay {
                  Image(systemName: "arrow.right")
                    .font(.system(size: 16))
                    .foregroundStyle(.offWhite)
                    .padding()
                }
            }
            .padding(.leading, 24)
            .padding(.trailing, 10)
            .frame(maxWidth: .infinity, maxHeight: 53)
            .glassEffect(.regular)
          } fallback: {
            Image(systemName: "xmark.circle")
            Text("Unavailable")
          }
        }

        Spacer()
          .frame(height: 40)

        // MARK: - 찾아낸 기기 리스트
        // 타이틀
        HStack {
          Text("찾아낸 기기")
            .foregroundStyle(gray3)
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
              if selectedPairedDevice == device
                && (networkState == .host(.publishing)
                  || networkState == .viewer(.browsing)
                  || networkState == .viewer(.connecting)
                  || networkState == .viewer(.connected)) {
                ProgressView()
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

        Spacer()
      }
      .padding(16)
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("기기 연결하기")
          .foregroundStyle(.offWhite)
      }

      ToolbarItem(placement: .topBarTrailing) {
        Button("Infomation", systemImage: "questionmark.circle") {
          //
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
    changeRoleButtonDidTap: { },
    connectButtonDidTap: { _ in }
  )
}
