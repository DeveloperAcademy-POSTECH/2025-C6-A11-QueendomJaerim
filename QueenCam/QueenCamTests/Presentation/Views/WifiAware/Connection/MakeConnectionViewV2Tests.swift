//
//  MakeConnectionViewV2Tests.swift
//  QueenCamTests
//

import Observation
import SwiftUI
import UIKit
import WiFiAware
import XCTest

@testable import QueenCam

@MainActor
final class MakeConnectionViewV2Tests: XCTestCase {
  private var mountedView: MountedMakeConnectionView?

  override func tearDown() {
    mountedView?.unmount()
    mountedView = nil
    super.tearDown()
  }

  func testEmptyAndNewDeviceStatesRenderDifferently() async {
    var mountedView = mount(role: .photographer, scenario: .empty)

    XCTAssertTrue(mountedView.state.devices.isEmpty)
    XCTAssertFalse(mountedView.makeConnectionView.isPairing)
    let emptySnapshot = mountedView.snapshotData()

    mountedView = mount(role: .photographer, scenario: .newDevice)
    await mountedView.waitForRendering()

    XCTAssertEqual(mountedView.state.devices.count, 5)
    XCTAssertEqual(mountedView.state.devices.first?.isNew, true)
    XCTAssertNotEqual(mountedView.snapshotData(), emptySnapshot)
  }

  func testRoleChangeCallbackUpdatesSpyState() async {
    let mountedView = mount(role: .photographer, scenario: .deviceList)
    let photographerSnapshot = mountedView.snapshotData()

    mountedView.makeConnectionView.changeRoleButtonDidTap()
    await mountedView.waitForRendering()

    XCTAssertEqual(mountedView.state.role, .model)
    XCTAssertEqual(mountedView.state.result, .roleChanged)
    XCTAssertNotEqual(mountedView.snapshotData(), photographerSnapshot)
  }

  func testConnectAndStopCallbacksUpdateSpyState() async throws {
    let mountedView = mount(role: .photographer, scenario: .deviceList)
    let device = try XCTUnwrap(mountedView.state.devices.first?.device)

    mountedView.makeConnectionView.connectButtonDidTap(device)
    await mountedView.waitForRendering()

    XCTAssertEqual(mountedView.state.selectedDevice, device)
    XCTAssertEqual(mountedView.state.networkState, .host(.publishing))
    XCTAssertEqual(mountedView.state.result, .connecting(device.id))
    XCTAssertTrue(mountedView.makeConnectionView.isPairing)

    mountedView.makeConnectionView.stopConnectingButtonDidTap()
    await mountedView.waitForRendering()

    XCTAssertNil(mountedView.state.selectedDevice)
    XCTAssertEqual(mountedView.state.networkState, .host(.stopped))
    XCTAssertEqual(mountedView.state.result, .stopped)
    XCTAssertFalse(mountedView.makeConnectionView.isPairing)
  }

  func testConnectedStateAndScreenSizesRender() {
    var mountedView = mount(
      role: .model,
      scenario: .connected,
      size: CGSize(width: 393, height: 852)
    )

    XCTAssertTrue(mountedView.state.isConnected)
    XCTAssertNotNil(mountedView.state.selectedDevice)
    XCTAssertEqual(mountedView.screenSize, CGSize(width: 393, height: 852))
    XCTAssertNotNil(mountedView.snapshotData())

    mountedView = mount(
      role: .photographer,
      scenario: .deviceList,
      languageCode: "en",
      size: CGSize(width: 1024, height: 1366)
    )

    XCTAssertEqual(mountedView.screenSize, CGSize(width: 1024, height: 1366))
    XCTAssertNotNil(mountedView.snapshotData())
  }

  private func mount(
    role: Role,
    scenario: MakeConnectionViewV2TestState.Scenario,
    languageCode: String = "ko",
    size: CGSize = CGSize(width: 393, height: 852)
  ) -> MountedMakeConnectionView {
    mountedView?.unmount()
    let mountedView = MountedMakeConnectionView(
      role: role,
      scenario: scenario,
      languageCode: languageCode,
      size: size
    )
    self.mountedView = mountedView
    return mountedView
  }
}

@MainActor
private final class MountedMakeConnectionView {
  let state: MakeConnectionViewV2TestState

  private let mountedTestView: MountedMakeConnectionTestView<MakeConnectionViewV2TestHost>

  var screenSize: CGSize {
    mountedTestView.size
  }

  var makeConnectionView: MakeConnectionViewV2 {
    MakeConnectionViewV2(
      role: state.role,
      networkState: state.networkState,
      selectedPairedDevice: state.selectedDevice,
      pairedDevices: state.devices,
      isConnected: state.isConnected,
      pairingButtonContent: AnyView(Color.clear),
      errorWasConsumeByUser: state.consumeError,
      changeRoleButtonDidTap: state.changeRole,
      connectButtonDidTap: state.connect,
      stopConnectingButtonDidTap: state.stopConnecting
    )
  }

  init(
    role: Role,
    scenario: MakeConnectionViewV2TestState.Scenario,
    languageCode: String,
    size: CGSize
  ) {
    let state = MakeConnectionViewV2TestState(role: role, scenario: scenario)
    self.state = state
    mountedTestView = MountedMakeConnectionTestView(
      content: MakeConnectionViewV2TestHost(
        state: state,
        languageCode: languageCode
      ),
      size: size
    )
  }

  func snapshotData() -> Data? {
    mountedTestView.snapshotData()
  }

  func waitForRendering() async {
    await mountedTestView.waitForRendering()
  }

  func unmount() {
    mountedTestView.unmount()
  }
}

@MainActor
private final class MountedMakeConnectionTestView<Content: View> {
  private let window: UIWindow
  private let hostingController: UIHostingController<Content>

  var size: CGSize {
    window.bounds.size
  }

  init(content: Content, size: CGSize) {
    hostingController = UIHostingController(rootView: content)
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      fatalError("UI 단위 테스트를 마운트할 UIWindowScene이 필요합니다.")
    }

    window = UIWindow(windowScene: windowScene)
    window.frame = CGRect(origin: .zero, size: size)
    window.rootViewController = hostingController
    window.makeKeyAndVisible()
    layout()
  }

  func snapshotData() -> Data? {
    layout()
    let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
    return renderer.image { _ in
      window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }.pngData()
  }

  func waitForRendering() async {
    await Task.yield()
    try? await Task.sleep(for: .milliseconds(50))
    layout()
  }

  func unmount() {
    window.isHidden = true
    window.rootViewController = nil
  }

  private func layout() {
    hostingController.view.frame = window.bounds
    hostingController.view.setNeedsLayout()
    hostingController.view.layoutIfNeeded()
  }
}

@MainActor
@Observable
private final class MakeConnectionViewV2TestState {
  enum Scenario: Equatable {
    case empty
    case deviceList
    case newDevice
    case connected
  }

  enum Result: Equatable {
    case presented
    case roleChanged
    case connecting(UInt64)
    case stopped
    case errorConsumed
  }

  var role: Role
  var networkState: NetworkState?
  var selectedDevice: WAPairedDevice?
  var devices: [ExtendedWAPairedDevice]
  var isConnected: Bool
  var result = Result.presented

  init(role: Role, scenario: Scenario) {
    let devices = Self.makeDevices(includeNewDevice: scenario == .newDevice)

    self.role = role
    networkState = .host(.stopped)
    selectedDevice = scenario == .connected ? devices.first?.device : nil
    self.devices = scenario == .empty ? [] : devices
    isConnected = scenario == .connected
  }

  func consumeError() {
    result = .errorConsumed
  }

  func changeRole() {
    role = role.counterpart
    result = .roleChanged
  }

  func connect(_ device: WAPairedDevice) {
    selectedDevice = device
    networkState = .host(.publishing)
    result = .connecting(device.id)
  }

  func stopConnecting() {
    selectedDevice = nil
    networkState = .host(.stopped)
    result = .stopped
  }
}

private extension MakeConnectionViewV2TestState {
  struct DeviceSpecification {
    let id: UInt64
    let name: String
    let lastConnectedAt: Date?
    let isNew: Bool
  }

  static func makeDevices(includeNewDevice: Bool) -> [ExtendedWAPairedDevice] {
    let allSpecifications = [
      DeviceSpecification(
        id: 1,
        name: "임영택의 iPhone 15",
        lastConnectedAt: nil,
        isNew: includeNewDevice
      ),
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
      DeviceSpecification(
        id: 4,
        name: "seungchan moon",
        lastConnectedAt: nil,
        isNew: false
      ),
      DeviceSpecification(
        id: 5,
        name: "Yoshi의 iPhone 17 Pro",
        lastConnectedAt: nil,
        isNew: false
      )
    ]

    let specifications = includeNewDevice
      ? allSpecifications
      : Array(allSpecifications.dropFirst())

    return specifications.compactMap { specification in
      guard
        let data = deviceJSON(
          id: specification.id,
          name: specification.name
        ).data(using: .utf8),
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
        "modelName": "UnitTest"
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

private struct MakeConnectionViewV2TestHost: View {
  @Bindable var state: MakeConnectionViewV2TestState
  let languageCode: String

  var body: some View {
    MakeConnectionViewV2(
      role: state.role,
      networkState: state.networkState,
      selectedPairedDevice: state.selectedDevice,
      pairedDevices: state.devices,
      isConnected: state.isConnected,
      pairingButtonContent: AnyView(Color.clear),
      errorWasConsumeByUser: state.consumeError,
      changeRoleButtonDidTap: state.changeRole,
      connectButtonDidTap: state.connect,
      stopConnectingButtonDidTap: state.stopConnecting
    )
    .environment(\.locale, Locale(identifier: languageCode))
  }
}
