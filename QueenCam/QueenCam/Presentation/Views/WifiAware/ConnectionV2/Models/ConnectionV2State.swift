import Foundation
import SwiftUI
import WiFiAware

enum ConnectionV2Step: Equatable {
  case roleSelection
  case deviceList
}

enum ConnectionAttemptState: Equatable {
  case idle
  case connecting(deviceName: String)
  case failed
}

enum DeviceConnectionHistoryStatus: Equatable {
  case newlyRegistered
  case lastConnected(Date)
  case neverConnected

  var localizedText: String {
    switch self {
    case .newlyRegistered:
      return String(localized: "새로 등록된 기기")
    case .lastConnected(let date):
      let formattedDate = date.formatted(
        Date.FormatStyle()
          .year(.twoDigits)
          .month(.defaultDigits)
          .day(.defaultDigits)
          .locale(Locale(identifier: "ko_KR"))
      )
      return String(localized: "최근 연결: \(formattedDate)")
    case .neverConnected:
      return String(localized: "최근 연결 기록이 없어요.")
    }
  }

  var foregroundStyle: Color {
    switch self {
    case .newlyRegistered, .lastConnected:
      return .contentPrimary
    case .neverConnected:
      return .gray400
    }
  }
}

struct ConnectionDeviceRowState: Identifiable {
  let id: UUID
  let device: WAPairedDevice
  let name: String
  let historyStatus: DeviceConnectionHistoryStatus

  init(
    id: UUID,
    device: WAPairedDevice,
    name: String,
    historyStatus: DeviceConnectionHistoryStatus
  ) {
    self.id = id
    self.device = device
    self.name = name
    self.historyStatus = historyStatus
  }

  init(device: ExtendedWAPairedDevice) {
    id = device.id
    self.device = device.device
    name = device.pairingName ?? device.name

    if device.isNew {
      historyStatus = .newlyRegistered
    } else if let lastConnectedAt = device.lastConnectedAt {
      historyStatus = .lastConnected(lastConnectedAt)
    } else {
      historyStatus = .neverConnected
    }
  }
}

extension Role {
  var displayName: String {
    switch self {
    case .photographer: return String(localized: "촬영")
    case .model: return String(localized: "모델")
    }
  }

  var userDescription: String {
    switch self {
    case .photographer:
      return String(localized: "내 기기로 사진을 촬영해요.\n동시에 친구에게 화면을 실시간으로 공유합니다.")
    case .model:
      return String(localized: "내가 사진 속 주인공이에요.\n카메라 속 내 모습을 실시간으로 볼 수 있어요.")
    }
  }

  var connectionV2PrimaryColor: Color {
    switch self {
    case .photographer: return .photographerPrimary
    case .model: return .modelPrimary
    }
  }

  var connectionV2SecondaryColor: Color {
    switch self {
    case .photographer: return .photographerS100
    case .model: return .modelS100
    }
  }

  var connectionV2DisabledColor: Color {
    switch self {
    case .photographer: return .photographerDisabled
    case .model: return .modelDisabled
    }
  }

  var connectionV2ModeName: LocalizedStringKey {
    switch self {
    case .photographer: return "촬영 모드"
    case .model: return "모델 모드"
    }
  }

  var connectionV2StartButtonTitle: LocalizedStringKey {
    switch self {
    case .photographer: return "촬영으로 시작하기"
    case .model: return "모델로 시작하기"
    }
  }
}
