//
//  QueenCamAppDelegate.swift
//  QueenCam
//
//  Created by 임영택 on 11/12/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAnalytics

final class QueenCamAppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()

    return true
  }
}
