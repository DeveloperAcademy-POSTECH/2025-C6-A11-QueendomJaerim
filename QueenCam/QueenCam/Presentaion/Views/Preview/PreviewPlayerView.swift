//
//  PreviewPlayerView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Foundation
import SwiftUI

struct PreviewPlayerView: View {
  let previewModel: PreviewStreamingViewModel

  var body: some View {
    if let imageSize = previewModel.imageSize {

      CameraPreviewMTKViewContainer(
        currentFrame: previewModel.lastReceivedFrameDecoded,
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
}
