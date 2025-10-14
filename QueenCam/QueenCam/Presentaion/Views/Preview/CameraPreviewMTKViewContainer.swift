//
//  CameraPreviewMTKViewContainer.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Combine
import Foundation
import SwiftUI

struct CameraPreviewMTKViewContainer: UIViewControllerRepresentable {
  var currentFrame: VideoFrameDecoded?

  let frameDidSkippedAction: (Double) -> Void
  let frameDidRenderStablyAction: () -> Void

  func makeUIViewController(context: Context) -> CameraPreviewMTKViewController {
    CameraPreviewMTKViewController()
  }

  func updateUIViewController(_ uiViewController: CameraPreviewMTKViewController, context: Context) {
    uiViewController.renderFrame(frame: currentFrame)
    uiViewController.delegate = context.coordinator
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(frameDidSkippedAction: frameDidSkippedAction, frameDidRenderStablyAction: frameDidRenderStablyAction)
  }

  class Coordinator: CameraPreviewMTKViewControllerDeletegate {
    let frameDidSkippedAction: (Double) -> Void
    let frameDidRenderStablyAction: () -> Void

    init(frameDidSkippedAction: @escaping (Double) -> Void, frameDidRenderStablyAction: @escaping () -> Void) {
      self.frameDidSkippedAction = frameDidSkippedAction
      self.frameDidRenderStablyAction = frameDidRenderStablyAction
    }

    func frameDidSkipped(viewController: CameraPreviewMTKViewController, diff: Double) {
      frameDidSkippedAction(diff)
    }

    func frameDidRenderStably(viewController: CameraPreviewMTKViewController) {
      frameDidRenderStablyAction()
    }
  }
}
