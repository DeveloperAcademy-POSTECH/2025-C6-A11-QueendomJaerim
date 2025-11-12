//
//  QueenCamApp.swift
//  QueenCam
//
//  Created by 임영택 on 9/19/25.
//

import SwiftUI

@main
struct QueenCamApp: App {
  @UIApplicationDelegateAdaptor(QueenCamAppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      MainView()
    }
  }
}
