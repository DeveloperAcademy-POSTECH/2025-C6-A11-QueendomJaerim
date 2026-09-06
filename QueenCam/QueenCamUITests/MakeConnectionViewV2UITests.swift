//
//  MakeConnectionViewV2UITests.swift
//  QueenCamUITests
//
//  Created by 임영택 on 9/6/26.
//

import XCTest

final class MakeConnectionViewV2UITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testEmptyStatesAndPairingHelp() throws {
    var app = launch(role: .photographer, state: "empty")
    XCTAssertTrue(app.staticTexts["make-connection-v2.title"].waitForExistence(timeout: 5))

    XCTAssertEqual(app.staticTexts["make-connection-v2.role-label"].label, "촬영 모드")
    XCTAssertEqual(app.staticTexts["make-connection-v2.title"].label, "등록된 기기가 없습니다")
    XCTAssertFalse(app.scrollViews["make-connection-v2.device-list"].exists)
    assertPrimaryButtonFitsScreen(app)
    addScreenshot(named: "MakeConnectionViewV2-Photographer-Empty", app: app)

    app.buttons["make-connection-v2.pairing-help-button"].tap()
    XCTAssertTrue(
      app.otherElements["make-connection-v2.pairing-help-sheet"].waitForExistence(timeout: 2)
    )

    app.terminate()
    app = launch(role: .model, state: "empty")
    XCTAssertTrue(app.staticTexts["make-connection-v2.title"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["make-connection-v2.role-label"].label, "모델 모드")
    XCTAssertEqual(app.staticTexts["make-connection-v2.title"].label, "등록된 기기가 없습니다")
    assertPrimaryButtonFitsScreen(app)
    addScreenshot(named: "MakeConnectionViewV2-Model-Empty", app: app)
  }

  @MainActor
  func testDeviceListNewDeviceAndRoleChange() throws {
    let app = launch(role: .photographer, state: "new")
    XCTAssertTrue(app.staticTexts["make-connection-v2.title"].waitForExistence(timeout: 5))

    XCTAssertEqual(app.staticTexts["make-connection-v2.title"].label, "친구의 기기와 연결해주세요")
    XCTAssertTrue(app.scrollViews["make-connection-v2.device-list"].exists)
    XCTAssertEqual(app.staticTexts["make-connection-v2.device-name-1"].label, "임영택의 iPhone 15")
    XCTAssertEqual(app.staticTexts["make-connection-v2.device-detail-1"].label, "새로 등록된 기기")
    XCTAssertEqual(app.staticTexts["make-connection-v2.device-detail-2"].label, "최근 연결: 26. 2. 10")
    addScreenshot(named: "MakeConnectionViewV2-Photographer-New", app: app)

    app.buttons["make-connection-v2.change-role-button"].tap()
    XCTAssertEqual(app.staticTexts["make-connection-v2.role-label"].label, "모델 모드")
    XCTAssertEqual(app.staticTexts["make-connection-v2.test-result"].label, "role-changed")
  }

  @MainActor
  func testConnectStopAndConnectedStates() throws {
    var app = launch(role: .photographer, state: "list")
    XCTAssertTrue(app.staticTexts["make-connection-v2.title"].waitForExistence(timeout: 5))

    let connectButton = app.buttons["make-connection-v2.connect-button-2"]
    XCTAssertTrue(connectButton.exists)
    connectButton.tap()
    XCTAssertTrue(app.buttons["연결 중단"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.staticTexts["make-connection-v2.test-result"].label.hasPrefix("connecting-"))

    app.buttons["연결 중단"].tap()
    XCTAssertEqual(app.staticTexts["make-connection-v2.test-result"].label, "stopped")
    XCTAssertTrue(app.buttons["make-connection-v2.connect-button-2"].exists)

    app.terminate()
    app = launch(role: .model, state: "connected")
    XCTAssertTrue(app.staticTexts["make-connection-v2.title"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.images["연결 완료"].exists || app.otherElements["연결 완료"].exists)
    addScreenshot(named: "MakeConnectionViewV2-Model-Connected", app: app)
  }

  @MainActor
  func testEnglishAndIPadContentDoesNotClip() throws {
    let app = launch(role: .photographer, state: "list", language: "en", locale: "en_US")
    XCTAssertTrue(app.staticTexts["make-connection-v2.title"].waitForExistence(timeout: 5))

    assertPrimaryButtonFitsScreen(app)
    let windowFrame = app.windows.firstMatch.frame
    for button in app.buttons.allElementsBoundByIndex where button.isHittable {
      XCTAssertGreaterThanOrEqual(button.frame.minX, windowFrame.minX)
      XCTAssertLessThanOrEqual(button.frame.maxX, windowFrame.maxX)
    }
  }
}

private extension MakeConnectionViewV2UITests {
  enum TestRole {
    case photographer
    case model
  }

  @MainActor
  func launch(
    role: TestRole,
    state: String,
    language: String = "ko",
    locale: String = "ko_KR"
  ) -> XCUIApplication {
    addUIInterruptionMonitor(withDescription: "사진 보관함 권한") { alert in
      let fullAccessButton = alert.buttons["전체 접근 허용"]
      let englishFullAccessButton = alert.buttons["Allow Full Access"]

      if fullAccessButton.exists {
        fullAccessButton.tap()
        return true
      }
      if englishFullAccessButton.exists {
        englishFullAccessButton.tap()
        return true
      }
      return false
    }

    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing-make-connection-v2",
      "--make-connection-v2-state", state,
      "-AppleLanguages", "(\(language))",
      "-AppleLocale", locale
    ]
    if role == .model {
      app.launchArguments.append("--model")
    }
    app.launch()
    app.tap()
    return app
  }

  @MainActor
  func assertPrimaryButtonFitsScreen(
    _ app: XCUIApplication,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let button = app.staticTexts["새로운 기기 페어링하기"]
    let windowFrame = app.windows.firstMatch.frame
    XCTAssertTrue(button.exists, file: file, line: line)
    XCTAssertGreaterThanOrEqual(button.frame.minX, windowFrame.minX, file: file, line: line)
    XCTAssertLessThanOrEqual(button.frame.maxX, windowFrame.maxX, file: file, line: line)
  }

  func addScreenshot(named name: String, app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
