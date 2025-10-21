//
//  PreviewPlayerView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Foundation
import SwiftUI

struct PreviewPlayerView: View {
  let previewModel: PreviewModel

  var body: some View {
    CameraPreviewDisplayViewContainer(
      currentSampleBuffer: previewModel.lastReceivedCMSampleBuffer,
      frameDidSkippedAction: { diff in
        previewModel.frameDidSkipped()
      },
      frameDidRenderStablyAction: {
        previewModel.frameDidRenderStablely()
      }
    )
    .aspectRatio(3 / 4, contentMode: .fit)
  }
}
