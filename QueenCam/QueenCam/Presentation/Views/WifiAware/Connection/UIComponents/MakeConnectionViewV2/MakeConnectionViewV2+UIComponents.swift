//
//  MakeConnectionViewV2+UIComponents.swift
//  QueenCam
//
//  Created by 임영택 on 9/6/26.
//

import DeviceDiscoveryUI
import SwiftUI
import WiFiAware

extension MakeConnectionViewV2 {
  var navigationControls: some View {
    HStack {
      dismissButton(
        systemName: "chevron.left",
        identifier: "make-connection-v2.back-button"
      )

      Spacer()

      dismissButton(
        systemName: "xmark",
        identifier: "make-connection-v2.close-button"
      )
    }
    .padding(.horizontal, 8.5)
  }

  var roleControls: some View {
    HStack(spacing: 8) {
      Text(role.modeTitle)
        .typo(.sb12)
        .foregroundStyle(role.secondaryColor)
        .padding(.horizontal, 12)
        .frame(height: 26)
        .background(role.disabledColor, in: Capsule())
        .accessibilityIdentifier("make-connection-v2.role-label")

      Button(action: changeRoleButtonDidTap) {
        Image(systemName: "arrow.left.arrow.right")
          .font(.system(size: 11, weight: .regular))
          .foregroundStyle(.systemWhite)
          .frame(width: 26, height: 26)
          .background(Color.gray700, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("역할 바꾸기")
      .accessibilityIdentifier("make-connection-v2.change-role-button")

      Spacer()
    }
    .padding(.horizontal, 16)
  }

  var connectionHeader: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(connectionTitle)
        .typo(.b22)
        .foregroundStyle(.systemWhite)
        .accessibilityIdentifier("make-connection-v2.title")

      Text(connectionSubtitle)
      .typo(.m14)
      .foregroundStyle(.gray400)
      .accessibilityIdentifier("make-connection-v2.subtitle")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  var pairedDeviceList: some View {
    if pairedDevices.isEmpty {
      Spacer(minLength: 0)
    } else {
      ScrollView(showsIndicators: false) {
        LazyVStack(spacing: 10) {
          ForEach(pairedDevices) { item in
            PairedDeviceRow(
              item: item,
              isSelected: item.device == selectedPairedDevice,
              isConnected: isConnected,
              connectButtonDidTap: connectButtonDidTap
            )
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
      }
      .accessibilityIdentifier("make-connection-v2.device-list")
    }
  }

  var bottomControls: some View {
    VStack(spacing: 8) {
      if pairedDevices.first?.isNew != true {
        Button {
          isShowingPairingHelp = true
        } label: {
          Text("페어링이 처음이라면?")
            .typo(.m14)
            .underline()
            .foregroundStyle(.gray400)
            .frame(width: 240, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("make-connection-v2.pairing-help-button")
      }

      Group {
        if let pairingButtonContent {
          pairingButtonContent
        } else {
          PairingButton(role: role)
        }
      }
        .frame(height: 56)
        .padding(.horizontal, 16)
        .accessibilityIdentifier("make-connection-v2.pairing-button")
    }
    .padding(.bottom, 25)
    .background(
      LinearGradient(
        colors: [backgroundColor.opacity(0), backgroundColor],
        startPoint: .top,
        endPoint: .center
      )
      .ignoresSafeArea()
    )
  }
}

extension MakeConnectionViewV2 {
  struct PairedDeviceRow: View {
    let item: ExtendedWAPairedDevice
    let isSelected: Bool
    let isConnected: Bool
    let connectButtonDidTap: (WAPairedDevice) -> Void

    private let connectedColor = Color(
      red: 39 / 255,
      green: 200 / 255,
      blue: 64 / 255
    )

    var body: some View {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(item.pairingName ?? item.name)
            .typo(.m15)
            .foregroundStyle(.systemWhite)
            .lineLimit(1)
            .accessibilityIdentifier("make-connection-v2.device-name-\(item.device.id)")

          supplementaryText
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        connectionControl
          .frame(width: LocaleUtils.currentLocale == .korean ? 75 : 100)
      }
      .padding(.horizontal, 20)
      .frame(height: 75)
      .background(item.isNew ? Color.gray900 : Color.gray950)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.systemWhite.opacity(item.isNew ? 0 : 0.04), lineWidth: 1)
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("make-connection-v2.device-row-\(item.device.id)")
    }

    @ViewBuilder
    private var supplementaryText: some View {
      if item.isNew {
        Text("새로 등록된 기기")
          .font(.pretendard(.bold, size: 12))
          .foregroundStyle(.systemWhite)
          .frame(height: 16)
          .accessibilityIdentifier("make-connection-v2.device-detail-\(item.device.id)")
      } else if let lastConnectedAt = item.lastConnectedAt {
        Text("최근 연결: \(Self.dateFormatter.string(from: lastConnectedAt))")
          .typo(.r12)
          .foregroundStyle(.systemWhite)
          .accessibilityIdentifier("make-connection-v2.device-detail-\(item.device.id)")
      } else {
        Text("최근 연결 기록이 없어요.")
          .typo(.r12)
          .foregroundStyle(.gray400)
          .accessibilityIdentifier("make-connection-v2.device-detail-\(item.device.id)")
      }
    }

    @ViewBuilder
    private var connectionControl: some View {
      if isSelected && isConnected {
        Image(systemName: "checkmark")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.originalWhite)
          .frame(width: 29, height: 29)
          .background(connectedColor, in: Circle())
          .accessibilityLabel("연결 완료")
      } else {
        Button {
          connectButtonDidTap(item.device)
        } label: {
          Text("연결")
            .typo(.sb14)
            .foregroundStyle(.systemWhite)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(Color.gray700, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("make-connection-v2.connect-button-\(item.device.id)")
      }
    }

    private static let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.locale = Locale(identifier: "ko_KR")
      formatter.dateFormat = "yy. M. d"
      return formatter
    }()
  }
}

extension MakeConnectionViewV2 {
  struct PairingButton: View {
    let role: Role

    private let devicePickerLogger = QueenLogger(category: "MakeConnectionViewV2+DevicePicker")

    var body: some View {
      if role == .photographer {
        DevicePairingView(.wifiAware(.connecting(to: .previewService, from: .userSpecifiedDevices))) {
          label
        } fallback: {
          label
        }
      } else {
        DevicePicker(.wifiAware(.connecting(to: .userSpecifiedDevices, from: .previewService))) { endpoint in
          devicePickerLogger.info("publisher did select endpoint - \(endpoint)")
        } label: {
          label
        } fallback: {
          label
        }
      }
    }

    private var label: some View {
      Text("새로운 기기 페어링하기")
        .typo(.sb16)
        .foregroundStyle(.gray950)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(role.primaryColor, in: RoundedRectangle(cornerRadius: 12))
    }
  }
}

private extension Role {
  var modeTitle: LocalizedStringKey {
    switch self {
    case .photographer: "촬영 모드"
    case .model: "모델 모드"
    }
  }

  var primaryColor: Color {
    switch self {
    case .photographer: .photographerPrimary
    case .model: .modelPrimary
    }
  }

  var secondaryColor: Color {
    switch self {
    case .photographer: .photographerS100
    case .model: .modelS100
    }
  }

  var disabledColor: Color {
    switch self {
    case .photographer: .photographerDisabled
    case .model: .modelDisabled
    }
  }
}
