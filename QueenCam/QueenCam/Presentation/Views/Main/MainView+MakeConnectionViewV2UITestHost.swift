//
//  MainView+MakeConnectionViewV2UITestHost.swift
//  QueenCam
//
//  Created by 임영택 on 9/6/26.
//

#if DEBUG
import SwiftUI
import WiFiAware

struct MakeConnectionViewV2UITestHost: View {
  @State private var role: Role
  @State private var networkState: NetworkState?
  @State private var selectedDevice: WAPairedDevice?
  @State private var isConnected: Bool
  @State private var result = "presented"

  private let devices: [ExtendedWAPairedDevice]

  init() {
    let arguments = ProcessInfo.processInfo.arguments
    let initialRole: Role = arguments.contains("--model") ? .model : .photographer
    let state = arguments.value(after: "--make-connection-v2-state") ?? "empty"
    let devices = Self.makeDevices(includeNewDevice: state == "new")
    let selectedDevice = (state == "connecting" || state == "connected") ? devices.first?.device : nil

    _role = State(initialValue: initialRole)
    _networkState = State(initialValue: state == "connecting" ? .host(.publishing) : .host(.stopped))
    _selectedDevice = State(initialValue: selectedDevice)
    _isConnected = State(initialValue: state == "connected")
    self.devices = state == "empty" ? [] : devices
  }

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      MakeConnectionViewV2(
        role: role,
        networkState: networkState,
        selectedPairedDevice: selectedDevice,
        pairedDevices: devices,
        isConnected: isConnected,
        errorWasConsumeByUser: { },
        changeRoleButtonDidTap: {
          role = role.counterpart
          result = "role-changed"
        },
        connectButtonDidTap: { device in
          selectedDevice = device
          networkState = .host(.publishing)
          result = "connecting-\(device.id)"
        },
        stopConnectingButtonDidTap: {
          selectedDevice = nil
          networkState = .host(.stopped)
          result = "stopped"
        }
      )

      Text(result)
        .frame(width: 1, height: 1)
        .opacity(0.001)
        .accessibilityIdentifier("make-connection-v2.test-result")
    }
  }
}

private extension MakeConnectionViewV2UITestHost {
  struct DeviceSpecification {
    let id: UInt64
    let name: String
    let lastConnectedAt: Date?
    let isNew: Bool
  }

  static func makeDevices(includeNewDevice: Bool) -> [ExtendedWAPairedDevice] {
    let allSpecifications = [
      DeviceSpecification(id: 1, name: "임영택의 iPhone 15", lastConnectedAt: nil, isNew: includeNewDevice),
      DeviceSpecification(
        id: 2,
        name: "차차폰",
        lastConnectedAt: makeDate(year: 2026, month: 2, day: 10),
        isNew: false
      ),
      DeviceSpecification(
        id: 3,
        name: "iPhone von Bota",
        lastConnectedAt: makeDate(year: 2025, month: 12, day: 12),
        isNew: false
      ),
      DeviceSpecification(id: 4, name: "seungchan moon", lastConnectedAt: nil, isNew: false),
      DeviceSpecification(id: 5, name: "Yoshi의 iPhone 17 Pro", lastConnectedAt: nil, isNew: false)
    ]

    let specifications = includeNewDevice ? allSpecifications : Array(allSpecifications.dropFirst())

    return specifications.compactMap { specification in
      guard let data = deviceJSON(id: specification.id, name: specification.name).data(using: .utf8),
        let device = try? JSONDecoder().decode(WAPairedDevice.self, from: data)
      else {
        return nil
      }

      let record = StoredDeviceSnapshot(
        id: UUID(),
        device: device,
        createdAt: makeDate(year: 2025, month: 1, day: 1),
        lastConnectedAt: specification.lastConnectedAt
      )
      return ExtendedWAPairedDevice(device: device, record: record, isNew: specification.isNew)
    }
  }

  static func deviceJSON(id: UInt64, name: String) -> String {
    """
    {
      "id": \(id),
      "name": "\(name)",
      "pairingInfo": {
        "pairingName": "\(name)",
        "vendorName": "QueenDom",
        "modelName": "UITest"
      }
    }
    """
  }

  static func makeDate(year: Int, month: Int, day: Int) -> Date {
    Calendar(identifier: .gregorian).date(
      from: DateComponents(year: year, month: month, day: day)
    ) ?? .distantPast
  }
}

private extension Array where Element == String {
  func value(after argument: String) -> String? {
    guard let index = firstIndex(of: argument), indices.contains(index + 1) else {
      return nil
    }
    return self[index + 1]
  }
}
#endif
