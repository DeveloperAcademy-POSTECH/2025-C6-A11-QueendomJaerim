//
//  GlobalDeviceEventTracer.swift
//  QueenCam
//
//  Created by 임영택 on 2/9/26.
//

import Foundation
import UIKit

final class GlobalDeviceEventObserver {
  init() {
    addObserver(forName: UIApplication.userDidTakeScreenshotNotification, using: handleTakeScreenshot)
    addObserver(forName: UIScreen.capturedDidChangeNotification, using: handleCaptureStatusChanged)
  }

  private func addObserver(forName notificationName: NSNotification.Name, using handler: @escaping (Notification) -> Void) {
    NotificationCenter.default.addObserver(
      forName: notificationName,
      object: nil,
      queue: .main,
      using: handler
    )
  }
}

extension GlobalDeviceEventObserver {
  private func handleTakeScreenshot(_ notification: Notification) {
    AnalyticsService.sendEvent(.takeScreenshot)
  }

  private func handleCaptureStatusChanged(_ notification: Notification) {
    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    let mainScreen = windowScene?.screen
    if let mainScreen, mainScreen.isCaptured {
      AnalyticsService.sendEvent(.takeVideoCapture)
    }
  }
}
