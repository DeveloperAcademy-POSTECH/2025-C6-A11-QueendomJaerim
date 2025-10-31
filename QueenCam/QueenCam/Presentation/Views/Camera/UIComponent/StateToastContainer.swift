//
//  StateToastContainer.swift
//  QueenCam
//
//  Created by 임영택 on 10/31/25.
//

import SwiftUI

struct StateToastContainer: View {
  @State private var stateToastViewModel = StateToastContainerViewModel()

  var body: some View {
    VStack {
      if let notification = stateToastViewModel.lastNotificationMessage {
        StateToast(message: notification.message, isImportant: notification.isImportant)
      }

      Spacer()
    }
    .animation(.easeInOut, value: stateToastViewModel.lastNotificationMessage)
  }
}
