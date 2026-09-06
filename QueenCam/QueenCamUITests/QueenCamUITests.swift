//
//  QueenCamUITests.swift
//  QueenCamUITests
//
//  Created by 임영택 on 9/19/25.
//

import XCTest

final class QueenCamUITests: XCTestCase {
  private enum HorizontalEdge {
    case minX
    case maxX
  }

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  @MainActor
  func testExample() throws {
    // UI tests must launch the application that they test.
    let app = XCUIApplication()
    app.launch()

    // Use XCTAssert and related functions to verify your tests produce the correct results.
  }

  @MainActor
  func testLaunchPerformance() throws {
    // This measures how long it takes to launch your application.
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      XCUIApplication().launch()
    }
  }

  @MainActor
  func testSelectRoleViewV2StatesAndJointMovement() throws {
    let app = launchSelectRoleViewV2(language: "ko", locale: "ko_KR")
    let screen = app.otherElements["select-role-v2.screen"]
    XCTAssertTrue(screen.waitForExistence(timeout: 5))

    let photographerButton = app.buttons["select-role-v2.photographer-button"]
    let modelButton = app.buttons["select-role-v2.model-button"]
    let primaryButton = app.buttons["select-role-v2.primary-button"]

    XCTAssertTrue(photographerButton.exists)
    XCTAssertTrue(modelButton.exists)
    XCTAssertFalse(primaryButton.isEnabled)
    XCTAssertEqual(primaryButton.label, "역할을 선택해주세요")

    let initialPhotographerFrame = photographerButton.frame
    let initialModelFrame = modelButton.frame
    assertRoleButtonsKeepStride(
      photographerFrame: initialPhotographerFrame,
      modelFrame: initialModelFrame
    )
    addScreenshot(named: "SelectRoleViewV2-Unselected", app: app)

    photographerButton.tap()
    waitForRoleAnimation()
    XCTAssertEqual(primaryButton.label, "촬영으로 시작하기")
    XCTAssertTrue(primaryButton.isEnabled)
    XCTAssertTrue(app.buttons["select-role-v2.selected-role-description"].exists)

    let selectedPhotographerFrame = photographerButton.frame
    let photographerStateModelFrame = modelButton.frame
    assertEqualMovement(
      firstBefore: initialPhotographerFrame,
      firstAfter: selectedPhotographerFrame,
      secondBefore: initialModelFrame,
      secondAfter: photographerStateModelFrame,
      edge: .minX,
      expectedMovement: 72.5
    )
    addScreenshot(named: "SelectRoleViewV2-Photographer", app: app)

    photographerButton.tap()
    waitForRoleAnimation()
    XCTAssertFalse(primaryButton.isEnabled)
    XCTAssertEqual(primaryButton.label, "역할을 선택해주세요")

    photographerButton.tap()
    waitForRoleAnimation()
    XCTAssertEqual(primaryButton.label, "촬영으로 시작하기")

    modelButton.tap()
    waitForRoleAnimation()
    XCTAssertEqual(primaryButton.label, "모델로 시작하기")

    let modelStatePhotographerFrame = photographerButton.frame
    let selectedModelFrame = modelButton.frame
    assertEqualMovement(
      firstBefore: initialPhotographerFrame,
      firstAfter: modelStatePhotographerFrame,
      secondBefore: initialModelFrame,
      secondAfter: selectedModelFrame,
      edge: .maxX,
      expectedMovement: -72.5
    )
    addScreenshot(named: "SelectRoleViewV2-Model", app: app)

    screen.swipeRight()
    waitForRoleAnimation()
    XCTAssertEqual(primaryButton.label, "촬영으로 시작하기")

    screen.swipeLeft()
    waitForRoleAnimation()
    XCTAssertEqual(primaryButton.label, "모델로 시작하기")

    modelButton.tap()
    XCTAssertFalse(primaryButton.isEnabled)
    XCTAssertEqual(primaryButton.label, "역할을 선택해주세요")
  }

  @MainActor
  func testSelectRoleViewV2SubmitAndDismiss() throws {
    var app = launchSelectRoleViewV2(language: "ko", locale: "ko_KR")
    XCTAssertTrue(app.otherElements["select-role-v2.screen"].waitForExistence(timeout: 5))

    let initialRoleButtonsFrame = app.buttons["select-role-v2.photographer-button"].frame.union(
      app.buttons["select-role-v2.model-button"].frame
    )

    app.buttons["select-role-v2.photographer-button"].tap()
    app.buttons["select-role-v2.primary-button"].tap()
    let transitionAnimation = app.images["select-role-v2.transition-animation"]
    XCTAssertTrue(transitionAnimation.waitForExistence(timeout: 1))
    XCTAssertEqual(transitionAnimation.frame.minX, initialRoleButtonsFrame.minX, accuracy: 1)
    XCTAssertEqual(transitionAnimation.frame.minY, initialRoleButtonsFrame.minY, accuracy: 1)
    XCTAssertEqual(transitionAnimation.frame.width, initialRoleButtonsFrame.width, accuracy: 1)
    XCTAssertEqual(transitionAnimation.frame.height, initialRoleButtonsFrame.height, accuracy: 1)

    let submittedResult = app.staticTexts["select-role-v2.test-result"]
    expectation(
      for: NSPredicate(format: "label == %@", "submitted"),
      evaluatedWith: submittedResult
    )
    waitForExpectations(timeout: 3)
    XCTAssertEqual(submittedResult.label, "submitted")

    app.terminate()
    app = launchSelectRoleViewV2(language: "ko", locale: "ko_KR")
    XCTAssertTrue(app.otherElements["select-role-v2.screen"].waitForExistence(timeout: 5))
    app.buttons["select-role-v2.close-button"].tap()

    let dismissedResult = app.staticTexts["select-role-v2.test-result"]
    expectation(
      for: NSPredicate(format: "label == %@", "dismissed"),
      evaluatedWith: dismissedResult
    )
    waitForExpectations(timeout: 2)
    XCTAssertEqual(dismissedResult.label, "dismissed")
  }

  @MainActor
  func testSelectRoleViewV2EnglishLocalization() throws {
    let app = launchSelectRoleViewV2(language: "en", locale: "en_US")
    XCTAssertTrue(app.otherElements["select-role-v2.screen"].waitForExistence(timeout: 5))

    let title = app.staticTexts["select-role-v2.title"]
    let subtitle = app.staticTexts["select-role-v2.subtitle"]

    XCTAssertEqual(title.label, "Please select your role")
    XCTAssertEqual(
      subtitle.label,
      "Only devices with different roles can connect.\nChoose a different role from your friend."
    )
    XCTAssertGreaterThanOrEqual(title.frame.minX, app.frame.minX)
    XCTAssertLessThanOrEqual(title.frame.maxX, app.frame.maxX)
    XCTAssertGreaterThanOrEqual(subtitle.frame.minX, app.frame.minX)
    XCTAssertLessThanOrEqual(subtitle.frame.maxX, app.frame.maxX)

    app.buttons["select-role-v2.photographer-button"].tap()
    let primaryButton = app.buttons["select-role-v2.primary-button"]
    XCTAssertEqual(primaryButton.label, "Start as Photographer")
    XCTAssertGreaterThanOrEqual(primaryButton.frame.minX, app.frame.minX)
    XCTAssertLessThanOrEqual(primaryButton.frame.maxX, app.frame.maxX)
  }

  @MainActor
  private func launchSelectRoleViewV2(language: String, locale: String) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing-select-role-v2",
      "-AppleLanguages", "(\(language))",
      "-AppleLocale", locale
    ]
    app.launch()
    return app
  }

  private func assertRoleButtonsKeepStride(
    photographerFrame: CGRect,
    modelFrame: CGRect,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(photographerFrame.width, 160, accuracy: 1, file: file, line: line)
    XCTAssertEqual(modelFrame.width, 160, accuracy: 1, file: file, line: line)
    XCTAssertEqual(
      modelFrame.midX - photographerFrame.midX,
      145,
      accuracy: 1,
      file: file,
      line: line
    )
  }

  private func assertEqualMovement(
    firstBefore: CGRect,
    firstAfter: CGRect,
    secondBefore: CGRect,
    secondAfter: CGRect,
    edge: HorizontalEdge,
    expectedMovement: CGFloat,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let firstMovement: CGFloat
    let secondMovement: CGFloat

    switch edge {
    case .minX:
      firstMovement = firstAfter.minX - firstBefore.minX
      secondMovement = secondAfter.minX - secondBefore.minX
    case .maxX:
      firstMovement = firstAfter.maxX - firstBefore.maxX
      secondMovement = secondAfter.maxX - secondBefore.maxX
    }

    XCTAssertEqual(
      firstMovement,
      secondMovement,
      accuracy: 1,
      file: file,
      line: line
    )
    XCTAssertEqual(firstMovement, expectedMovement, accuracy: 1, file: file, line: line)
  }

  private func addScreenshot(named name: String, app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func waitForRoleAnimation() {
    let animationExpectation = XCTestExpectation(description: "역할 버튼 애니메이션 완료")
    _ = XCTWaiter.wait(for: [animationExpectation], timeout: 0.6)
  }
}
