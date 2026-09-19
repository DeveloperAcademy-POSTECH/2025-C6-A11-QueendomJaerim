//
//  PairingGuideSheetViewTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 9/13/26.
//

import Observation
import SwiftUI
import UIKit
import XCTest

@testable import QueenCam

@MainActor
final class PairingGuideSheetViewTests: XCTestCase {
  private struct SnapshotScenario {
    let role: Role
    let attachmentName: String
  }

  private var mountedView: MountedPairingGuideSheetView?

  override func tearDown() {
    mountedView?.unmount()
    mountedView = nil
    super.tearDown()
  }

  func testDefaultItemsContainThreeOrderedPlaceholders() {
    let items = PairingGuideItem.defaults

    XCTAssertEqual(items.map(\.id), [1, 2, 3])
    XCTAssertTrue(items.allSatisfy { $0.imageAsset == nil })
  }

  func testCloseAndConfirmActionsInvokeCallback() {
    let mountedView = mount(role: .photographer)

    mountedView.sheetView.closeButtonDidTap()
    mountedView.state.present()
    mountedView.sheetView.confirmButtonDidTap()

    XCTAssertEqual(mountedView.state.dismissCallCount, 2)
    XCTAssertFalse(mountedView.state.isPresented)
  }

  func testPhotographerAndModelRenderAtFigmaCanvasSize() async {
    let scenarios = [
      SnapshotScenario(role: .photographer, attachmentName: "Photographer"),
      SnapshotScenario(role: .model, attachmentName: "Model")
    ]
    var snapshots: [Data] = []

    for scenario in scenarios {
      let mountedView = mount(
        role: scenario.role,
        size: CGSize(width: 393, height: 1459)
      )
      await mountedView.waitForPresentation()

      XCTAssertEqual(mountedView.screenSize, CGSize(width: 393, height: 1459))
      let image = mountedView.snapshotImage()
      XCTAssertEqual(image.size, mountedView.screenSize)
      if let data = image.pngData() {
        snapshots.append(data)
      }

      let attachment = XCTAttachment(image: image)
      attachment.name = "App-Pairing-Guide-\(scenario.attachmentName)-393x1459"
      attachment.lifetime = .keepAlways
      add(attachment)
    }

    XCTAssertEqual(snapshots.count, 2)
    XCTAssertNotEqual(snapshots[0], snapshots[1])
  }

  func testPresentationUsesLargeDetentWithVisibleGrabberAndRoundedCorners() async throws {
    let mountedView = mount(role: .photographer)
    await mountedView.waitForPresentation()

    let presentationController = try XCTUnwrap(mountedView.sheetPresentationController)

    XCTAssertEqual(presentationController.detents.map(\.identifier), [.large])
    XCTAssertTrue(presentationController.prefersGrabberVisible)
    XCTAssertEqual(presentationController.preferredCornerRadius, 38)
  }

  func testPlaceholdersRenderWithFigmaDimensions() async throws {
    let mountedView = mount(
      role: .model,
      size: CGSize(width: 393, height: 1024)
    )
    await mountedView.waitForPresentation()

    let placeholderBounds = try XCTUnwrap(
      mountedView.snapshotImage().pixelBounds(
        matching: UIColor(red: 43 / 255, green: 43 / 255, blue: 43 / 255, alpha: 1),
        tolerance: 4
      )
    )

    XCTAssertEqual(placeholderBounds.width, 353, accuracy: 2)
    XCTAssertGreaterThanOrEqual(placeholderBounds.height, 213)
  }

  func testConfirmButtonRemainsInsideWindowBounds() async throws {
    for size in [
      CGSize(width: 393, height: 852),
      CGSize(width: 1024, height: 1366)
    ] {
      let mountedView = mount(role: .photographer, size: size)
      await mountedView.waitForPresentation()

      let buttonBounds = try XCTUnwrap(
        mountedView.snapshotImage().pixelBounds(
          matching: UIColor(red: 3 / 255, green: 211 / 255, blue: 224 / 255, alpha: 1),
          tolerance: 4
        )
      )
      XCTAssertTrue(CGRect(origin: .zero, size: size).contains(buttonBounds))
    }
  }

  private func mount(
    role: Role,
    size: CGSize = CGSize(width: 393, height: 1024)
  ) -> MountedPairingGuideSheetView {
    mountedView?.unmount()
    let mountedView = MountedPairingGuideSheetView(role: role, size: size)
    self.mountedView = mountedView
    return mountedView
  }
}

@MainActor
private final class MountedPairingGuideSheetView {
  let state: PairingGuideSheetTestState

  private let role: Role
  private let mountedTestView: MountedPairingGuideTestView<PairingGuideSheetTestHost>

  var screenSize: CGSize {
    mountedTestView.size
  }

  var sheetView: PairingGuideSheetView {
    PairingGuideSheetView(role: role, dismissAction: state.dismiss)
  }

  var sheetPresentationController: UISheetPresentationController? {
    mountedTestView.sheetPresentationController
  }

  init(role: Role, size: CGSize) {
    let state = PairingGuideSheetTestState()
    self.state = state
    self.role = role
    mountedTestView = MountedPairingGuideTestView(
      content: PairingGuideSheetTestHost(state: state, role: role),
      size: size
    )
  }

  func snapshotImage() -> UIImage {
    mountedTestView.snapshotImage()
  }

  func waitForPresentation() async {
    await mountedTestView.waitForPresentation()
  }

  func unmount() {
    mountedTestView.unmount()
  }
}

@MainActor
@Observable
private final class PairingGuideSheetTestState {
  var isPresented = false
  private(set) var dismissCallCount = 0

  func present() {
    isPresented = true
  }

  func dismiss() {
    dismissCallCount += 1
    isPresented = false
  }
}

@MainActor
private final class MountedPairingGuideTestView<Content: View> {
  private let window: UIWindow
  private let hostingController: UIHostingController<Content>

  var size: CGSize {
    window.bounds.size
  }

  var sheetPresentationController: UISheetPresentationController? {
    window.rootViewController?.presentedViewController?.sheetPresentationController
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

  func waitForPresentation() async {
    await Task.yield()
    try? await Task.sleep(for: .milliseconds(500))
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

private struct PairingGuideSheetTestHost: View {
  @Bindable var state: PairingGuideSheetTestState
  let role: Role

  var body: some View {
    Color.black
      .ignoresSafeArea()
      .onAppear(perform: state.present)
      .sheet(isPresented: $state.isPresented) {
        PairingGuideSheetView(role: role, dismissAction: state.dismiss)
          .pairingSheetPresentationStyle()
      }
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
