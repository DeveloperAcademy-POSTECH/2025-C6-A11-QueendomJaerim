//
//  SelectRoleViewV2Tests.swift
//  QueenCamTests
//

import Observation
import SwiftUI
import UIKit
import XCTest

@testable import QueenCam

@MainActor
final class SelectRoleViewV2Tests: XCTestCase {
  private var mountedView: MountedSelectRoleView?

  override func tearDown() {
    mountedView?.unmount()
    mountedView = nil
    super.tearDown()
  }

  func testStatesAndJointMovement() async {
    let mountedView = mount(languageCode: "ko")
    let metrics = SelectRoleViewV2.RoleButtonMetrics.self
    let itemStride = metrics.size - metrics.overlap
    let selectedOffset = itemStride / 2

    XCTAssertEqual(mountedView.selectRoleView.roleSelectButtonsOffset, 0)

    let unselectedSnapshot = mountedView.snapshotData()

    mountedView.selectRoleView.didRoleSelect(.photographer)
    await mountedView.waitForRendering()
    XCTAssertEqual(mountedView.state.selectedRole, .photographer)
    XCTAssertEqual(
      mountedView.selectRoleView.roleSelectButtonsOffset,
      selectedOffset
    )
    XCTAssertNotEqual(mountedView.snapshotData(), unselectedSnapshot)

    mountedView.selectRoleView.didRoleSelect(.photographer)
    await mountedView.waitForRendering()
    XCTAssertNil(mountedView.state.selectedRole)
    XCTAssertEqual(mountedView.selectRoleView.roleSelectButtonsOffset, 0)

    mountedView.selectRoleView.didRoleSelect(.model)
    await mountedView.waitForRendering()
    XCTAssertEqual(mountedView.state.selectedRole, .model)
    XCTAssertEqual(
      mountedView.selectRoleView.roleSelectButtonsOffset,
      -selectedOffset
    )
  }

  func testSwipeChangesSelectedRole() {
    var selectedRole: Role? = .photographer
    let view = makeSelectRoleView(selectedRole: selectedRole) { selectedRole = $0 }

    view.didSwipe(direction: -1)
    XCTAssertEqual(selectedRole, .model)

    let modelView = makeSelectRoleView(selectedRole: selectedRole) { selectedRole = $0 }
    modelView.didSwipe(direction: 1)
    XCTAssertEqual(selectedRole, .photographer)

    selectedRole = nil
    let unselectedView = makeSelectRoleView(selectedRole: selectedRole) { selectedRole = $0 }
    unselectedView.didSwipe(direction: -1)
    XCTAssertNil(selectedRole)
  }

  func testSubmitAndDismissCallbacks() async {
    var mountedView = mount(languageCode: "ko")

    mountedView.selectRoleView.didRoleSelect(.photographer)
    mountedView.selectRoleView.didRoleSubmit()
    XCTAssertEqual(mountedView.state.result, .submitted)

    mountedView = mount(languageCode: "ko")
    mountedView.dismiss()
    await mountedView.waitForRendering()
    XCTAssertEqual(mountedView.state.result, .dismissed)
  }

  func testTransitionAnimationCompletesAfterMounting() async {
    let expectation = expectation(description: "전환 애니메이션 완료")
    let mountedTransition = MountedTestView(
      content: SelectRoleViewV2.TransitionAnimationView {
        expectation.fulfill()
      }
    )
    defer { mountedTransition.unmount() }

    await fulfillment(of: [expectation], timeout: 2)
  }

  func testEnglishLocalizationAndScreenSize() throws {
    let mountedView = mount(languageCode: "en")
    let appBundle = try XCTUnwrap(
      Bundle.allBundles.first { bundle in
        bundle.bundleURL.lastPathComponent == "QueenCam.app"
          && bundle.path(forResource: "en", ofType: "lproj") != nil
      }
    )
    let englishBundle = try XCTUnwrap(
      appBundle.path(forResource: "en", ofType: "lproj").flatMap(Bundle.init(path:))
    )

    XCTAssertEqual(
      englishBundle.localizedString(forKey: "역할을 선택해주세요", value: nil, table: nil),
      "Please select your role"
    )
    XCTAssertEqual(
      englishBundle.localizedString(
        forKey: "서로 다른 역할의 기기끼리만 연결할 수 있어요.\n친구와 다른 역할을 선택해주세요.",
        value: nil,
        table: nil
      ),
      "Only devices with different roles can connect.\nChoose a different role from your friend."
    )
    XCTAssertEqual(
      englishBundle.localizedString(forKey: "촬영으로 시작하기", value: nil, table: nil),
      "Start as Photographer"
    )
    XCTAssertEqual(mountedView.screenSize.width, 393)
    XCTAssertEqual(mountedView.screenSize.height, 852)
    XCTAssertNotNil(mountedView.snapshotData())
  }

  private func mount(languageCode: String) -> MountedSelectRoleView {
    mountedView?.unmount()
    let mountedView = MountedSelectRoleView(languageCode: languageCode)
    self.mountedView = mountedView
    return mountedView
  }

  private func makeSelectRoleView(
    selectedRole: Role?,
    didRoleSelect: @escaping (Role) -> Void
  ) -> SelectRoleViewV2 {
    SelectRoleViewV2(
      selectedRole: selectedRole,
      didRoleSelect: didRoleSelect
    ) {}
  }
}

@MainActor
private final class MountedSelectRoleView {
  let state = SelectRoleViewV2TestState()

  private let mountedTestView: MountedTestView<SelectRoleViewV2TestHost>

  var screenSize: CGSize {
    mountedTestView.size
  }

  var selectRoleView: SelectRoleViewV2 {
    SelectRoleViewV2(
      selectedRole: state.selectedRole,
      didRoleSelect: state.select,
      didRoleSubmit: state.submit
    )
  }

  init(languageCode: String) {
    mountedTestView = MountedTestView(
      content: SelectRoleViewV2TestHost(
        state: state,
        languageCode: languageCode
      )
    )
  }

  func dismiss() {
    state.dismiss()
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
private final class MountedTestView<Content: View> {
  private static var defaultSize: CGSize {
    CGSize(width: 393, height: 852)
  }

  private let window: UIWindow
  private let hostingController: UIHostingController<Content>

  var size: CGSize {
    window.bounds.size
  }

  init(content: Content) {
    hostingController = UIHostingController(rootView: content)
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      fatalError("UI 단위 테스트를 마운트할 UIWindowScene이 필요합니다.")
    }

    window = UIWindow(windowScene: windowScene)
    window.frame = CGRect(origin: .zero, size: Self.defaultSize)
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
private final class SelectRoleViewV2TestState {
  enum Result: Equatable {
    case presented
    case submitted
    case dismissed
  }

  var selectedRole: Role?
  var result = Result.presented

  func select(_ role: Role) {
    selectedRole = selectedRole == role ? nil : role
  }

  func submit() {
    result = .submitted
  }

  func dismiss() {
    result = .dismissed
  }
}

private struct SelectRoleViewV2TestHost: View {
  @Bindable var state: SelectRoleViewV2TestState
  let languageCode: String

  var body: some View {
    SelectRoleViewV2(
      selectedRole: state.selectedRole,
      didRoleSelect: state.select,
      didRoleSubmit: state.submit
    )
    .environment(\.locale, Locale(identifier: languageCode))
  }
}
