//
//  PreviewPlayerView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Foundation
import SwiftUI

struct DebugPreviewPlayerView: View {
  let previewModel: PreviewModel

  @State private var showingDebugInfo: Bool = false

  var body: some View {
    if let imageSize = previewModel.imageSize {

      ZStack {
        CameraPreviewMTKViewContainer(
          currentFrame: previewModel.lastReceivedFrameDecoded,
          frameDidSkippedAction: { diff in
            previewModel.frameDidSkipped()
          },
          frameDidRenderStablyAction: {
            previewModel.frameDidRenderStablely()
          }
        )

        if showingDebugInfo {
          DebugInfoOverlay(qualityLabel: previewModel.lastReceivedQuality?.displayLabel)
        }
      }
      .aspectRatio(3 / 4, contentMode: .fit)
      .onReceive(NotificationCenter.default.publisher(for: .QueenCamDeviceDidShakeNotification)) { _ in
        showingDebugInfo.toggle()
      }
    }
  }
}

struct DebugInfoOverlay: View {
  let qualityLabel: String?

  var body: some View {
    VStack {
      HStack {
        Text("\(qualityLabel ?? "N/A")")
        Spacer()
      }
      Spacer()
    }
    .padding()
  }
}
