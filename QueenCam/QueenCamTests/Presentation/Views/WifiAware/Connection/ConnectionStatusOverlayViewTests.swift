//
//  ConnectionStatusOverlayViewTests.swift
//  QueenCamTests
//

import SwiftUI
import UIKit
import XCTest

@testable import QueenCam

@MainActor
final class ConnectionStatusOverlayViewTests: XCTestCase {
  private struct SnapshotScenario {
    let role: Role
    let state: ConnectionStatusOverlayView.State
    let attachmentName: String
  }

  private var mountedView: MountedConnectionStatusOverlayView?

  override func tearDown() {
    mountedView?.unmount()
    mountedView = nil
    super.tearDown()
  }

  func testConnectingAndFailedStatesRenderDifferently() async {
    var mountedView = mount(
      role: .photographer,
      state: .connecting(deviceName: "임영택의 iPhone 16")
    )
    await mountedView.waitForRendering()
    let connectingSnapshot = mountedView.snapshotData()

    mountedView = mount(role: .photographer, state: .failed)
    await mountedView.waitForRendering()
    let failedSnapshot = mountedView.snapshotData()

    XCTAssertNotNil(connectingSnapshot)
    XCTAssertNotNil(failedSnapshot)
    XCTAssertNotEqual(connectingSnapshot, failedSnapshot)
  }

  func testPhotographerAndModelStatesRenderAtFigmaScreenSize() async {
    let scenarios: [SnapshotScenario] = [
      SnapshotScenario(
        role: .photographer,
        state: .connecting(deviceName: "임영택의 iPhone 16"),
        attachmentName: "Photographer-Connecting"
      ),
      SnapshotScenario(
        role: .model,
        state: .connecting(deviceName: "임영택의 iPhone 16"),
        attachmentName: "Model-Connecting"
      ),
      SnapshotScenario(
        role: .photographer,
        state: .failed,
        attachmentName: "Photographer-Failed"
      ),
      SnapshotScenario(
        role: .model,
        state: .failed,
        attachmentName: "Model-Failed"
      )
    ]

    for scenario in scenarios {
      let mountedView = mount(role: scenario.role, state: scenario.state)
      await mountedView.waitForRendering()

      XCTAssertEqual(mountedView.screenSize, CGSize(width: 393, height: 852))
      let image = mountedView.snapshotImage()
      XCTAssertEqual(image.size, mountedView.screenSize)

      let attachment = XCTAttachment(image: image)
      attachment.name = "App-\(scenario.attachmentName)-393x852"
      attachment.lifetime = .keepAlways
      add(attachment)
    }
  }

  func testLongDeviceNameAndEnglishLocaleRenderOnIPad() async {
    let mountedView = mount(
      role: .model,
      state: .connecting(
        deviceName: "This is a deliberately long paired device name for layout verification"
      ),
      languageCode: "en",
      size: CGSize(width: 1024, height: 1366)
    )
    await mountedView.waitForRendering()

    XCTAssertEqual(mountedView.screenSize, CGSize(width: 1024, height: 1366))
    XCTAssertEqual(mountedView.snapshotImage().size, mountedView.screenSize)
    XCTAssertGreaterThanOrEqual(mountedView.screenSize.width, 311)
    XCTAssertGreaterThanOrEqual(mountedView.screenSize.height, 278)
  }

  func testActionButtonRemainsInsideWindowBounds() async throws {
    for size in [CGSize(width: 393, height: 852), CGSize(width: 1024, height: 1366)] {
      let mountedView = mount(role: .model, state: .failed, size: size)
      await mountedView.waitForRendering()

      let buttonFrame = try XCTUnwrap(
        mountedView.snapshotImage().pixelBounds(
          matching: UIColor(red: 51 / 255, green: 51 / 255, blue: 51 / 255, alpha: 1)
        )
      )
      XCTAssertTrue(CGRect(origin: .zero, size: size).contains(buttonFrame))
    }
  }

  func testConnectingActionInvokesCallback() {
    let mountedView = mount(
      role: .photographer,
      state: .connecting(deviceName: "임영택의 iPhone 16")
    )

    mountedView.overlayView.actionButtonDidTap()

    XCTAssertEqual(mountedView.actionSpy.callCount, 1)
  }

  func testFailedActionInvokesCallback() {
    let mountedView = mount(role: .model, state: .failed)

    mountedView.overlayView.actionButtonDidTap()

    XCTAssertEqual(mountedView.actionSpy.callCount, 1)
  }

  private func mount(
    role: Role,
    state: ConnectionStatusOverlayView.State,
    languageCode: String = "ko",
    size: CGSize = CGSize(width: 393, height: 852)
  ) -> MountedConnectionStatusOverlayView {
    mountedView?.unmount()
    let mountedView = MountedConnectionStatusOverlayView(
      role: role,
      state: state,
      languageCode: languageCode,
      size: size
    )
    self.mountedView = mountedView
    return mountedView
  }
}

@MainActor
private final class MountedConnectionStatusOverlayView {
  let actionSpy: ConnectionStatusOverlayActionSpy

  private let state: ConnectionStatusOverlayView.State
  private let mountedTestView: MountedConnectionStatusOverlayTestView<ConnectionStatusOverlayTestHost>

  var screenSize: CGSize {
    mountedTestView.size
  }

  var overlayView: ConnectionStatusOverlayView {
    ConnectionStatusOverlayView(
      state: state,
      actionButtonDidTap: actionSpy.call
    )
  }

  init(
    role: Role,
    state: ConnectionStatusOverlayView.State,
    languageCode: String,
    size: CGSize
  ) {
    let actionSpy = ConnectionStatusOverlayActionSpy()
    self.actionSpy = actionSpy
    self.state = state
    mountedTestView = MountedConnectionStatusOverlayTestView(
      content: ConnectionStatusOverlayTestHost(
        role: role,
        state: state,
        languageCode: languageCode,
        actionButtonDidTap: actionSpy.call
      ),
      size: size
    )
  }

  func snapshotData() -> Data? {
    mountedTestView.snapshotImage().pngData()
  }

  func snapshotImage() -> UIImage {
    mountedTestView.snapshotImage()
  }

  func waitForRendering() async {
    await mountedTestView.waitForRendering()
  }

  func unmount() {
    mountedTestView.unmount()
  }
}

@MainActor
private final class ConnectionStatusOverlayActionSpy {
  private(set) var callCount = 0

  func call() {
    callCount += 1
  }
}

@MainActor
private final class MountedConnectionStatusOverlayTestView<Content: View> {
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

  func snapshotImage() -> UIImage {
    layout()
    let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
    return renderer.image { _ in
      window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
    }
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

private extension UIImage {
  func pixelBounds(matching color: UIColor, tolerance: UInt8 = 2) -> CGRect? {
    guard let cgImage,
      let components = color.cgColor.components,
      components.count >= 3 else {
      return nil
    }

    let width = cgImage.width
    let height = cgImage.height
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
    guard let context = CGContext(
      data: &pixels,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return nil
    }
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    let target = components.prefix(3).map { UInt8(($0 * 255).rounded()) }
    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1
    for y in 0..<height {
      for x in 0..<width {
        let offset = (y * bytesPerRow) + (x * bytesPerPixel)
        guard zip(pixels[offset..<(offset + 3)], target).allSatisfy({
          abs(Int($0.0) - Int($0.1)) <= Int(tolerance)
        }) else {
          continue
        }
        minX = min(minX, x)
        minY = min(minY, y)
        maxX = max(maxX, x)
        maxY = max(maxY, y)
      }
    }
    guard maxX >= minX, maxY >= minY else {
      return nil
    }

    return CGRect(
      x: CGFloat(minX) / scale,
      y: CGFloat(minY) / scale,
      width: CGFloat(maxX - minX + 1) / scale,
      height: CGFloat(maxY - minY + 1) / scale
    )
  }
}

private struct ConnectionStatusOverlayTestHost: View {
  let role: Role
  let state: ConnectionStatusOverlayView.State
  let languageCode: String
  let actionButtonDidTap: () -> Void

  var body: some View {
    ZStack {
      roleBackgroundColor
        .ignoresSafeArea()

      VStack(spacing: 12) {
        ForEach(0..<5, id: \.self) { _ in
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray950)
            .frame(height: 75)
        }
      }
      .padding(.horizontal, 16)

      ConnectionStatusOverlayView(
        state: state,
        actionButtonDidTap: actionButtonDidTap
      )
    }
    .environment(\.locale, Locale(identifier: languageCode))
  }

  private var roleBackgroundColor: Color {
    switch role {
    case .photographer:
      .photographerPrimary
    case .model:
      .modelPrimary
    }
  }
}
