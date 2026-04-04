//
//  AnalyticsService.swift
//  QueenCam
//
//  Created by 임영택 on 11/12/25.
//

import FirebaseAnalytics

final class AnalyticsService {
  private let screenContext: AnalyticsScreenContext

  private let logger = QueenLogger(category: "AnalyticsService")

  init(initialScreenStack: [AnalyticsScreenData] = []) {
    self.screenContext = AnalyticsScreenContext(screenStack: initialScreenStack)
    self.screenContext.delegate = self

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleNotification(_:)),
      name: .QueenCamAnalyticsEventNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleScreenNotification(_:)),
      name: .QueenCamAnalyticsScreenEventNotification,
      object: nil
    )

    logger.debug("AnalyticsService init")
  }

  @objc private func handleNotification(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
      let event = userInfo["event"] as? AnalyticsEvent
    else {
      logger.warning("received QueenCamAnalyticsEventNotification but payload is invalid type.")
      return
    }

    logEvent(event)
  }

  @objc private func handleScreenNotification(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
      let action = userInfo["screenAction"] as? AnalyticsScreenAction
    else {
      logger.warning("received QueenCamAnalyticsScreenEventNotification but payload is invalid type.")
      return
    }

    switch action {
    case .didAppear(let screen, let from, let id):
      screenContext.didAppear(screen, from: from, id: id)
    case .didDisappear(let screen, let from, let id):
      _ = screenContext.didDisappear(screen, from: from, id: id)
    case .reset:
      screenContext.reset()
    }
  }

  private func logEvent(_ event: AnalyticsEvent) {
    logger.debug("will send event: \(event.eventName) to FirebaseAnalytics")
    Analytics.logEvent(
      event.eventName,
      parameters: [
        AnalyticsParameterItemName: event.eventName,
        AnalyticsParameterContentType: event.eventType,
        AnalyticsParameterScreenName: screenContext.getLastScreen()?.screen.displayName ?? "unknown",
        AnalyticsParameterScreenClass: screenContext.getLastScreen()?.className ?? "unknown"
      ]
    )
  }
}

extension AnalyticsService {
  /// 앱의 어디든 아래 메서드를 이용하면 이벤트를 발행할 수 있다.
  /// 되도록 GA 이벤트 발행을 위해 NotificationCenter.default를 직접 참조하지 않는다.
  static func sendEvent(_ event: AnalyticsEvent) {
    NotificationCenter.default.post(
      name: .QueenCamAnalyticsEventNotification,
      object: nil,
      userInfo: ["event": event]
    )
  }

  /// 앱의 어디든 아래 메서드를 이용하면 화면 이동 이벤트를 발행할 수 있다.
  static func sendScreenEvent(_ action: AnalyticsScreenAction) {
    NotificationCenter.default.post(
      name: .QueenCamAnalyticsScreenEventNotification,
      object: nil,
      userInfo: ["screenAction": action]
    )
  }
}

extension AnalyticsService: AnalyticsScreenContextDelegate {
  // MARK: - Custom Parameter Keys
  private static let previousScreenNameKey = "previous_screen_name"
  private static let previousScreenClassKey = "previous_screen_class"

  func didChangeScreen(to newScreen: AnalyticsScreenData?, from oldScreen: AnalyticsScreenData?) {
    logger.debug(
      "will send screen event: new=\(String(describing: newScreen)) old=\(String(describing: oldScreen)) to FirebaseAnalytics"
    )
    guard let currentScreen = newScreen else { return }

    var parameters: [String: Any] = [
      AnalyticsParameterScreenName: currentScreen.screen.displayName,
      AnalyticsParameterScreenClass: currentScreen.className
    ]

    if let previousScreen = oldScreen {
      parameters[Self.previousScreenNameKey] = previousScreen.screen.displayName
      parameters[Self.previousScreenClassKey] = previousScreen.className
    }

    Analytics.logEvent(AnalyticsEventScreenView, parameters: parameters)
  }
}
