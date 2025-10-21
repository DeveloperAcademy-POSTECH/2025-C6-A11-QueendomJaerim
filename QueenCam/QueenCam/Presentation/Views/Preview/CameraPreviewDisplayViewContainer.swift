//
//  CameraPreviewMTKViewContainer.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Combine
import Foundation
import SwiftUI
import CoreMedia

struct CameraPreviewDisplayViewContainer: UIViewControllerRepresentable {
  var currentSampleBuffer: CMSampleBuffer?

  let frameDidSkippedAction: (Double) -> Void
  let frameDidRenderStablyAction: () -> Void

  func makeUIViewController(context: Context) -> CameraPreviewDisplayViewController {
    CameraPreviewDisplayViewController()
  }

  func updateUIViewController(_ uiViewController: CameraPreviewDisplayViewController, context: Context) {
    uiViewController.renderFrame(sampleBuffer: currentSampleBuffer)
    uiViewController.delegate = context.coordinator
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(frameDidSkippedAction: frameDidSkippedAction, frameDidRenderStablyAction: frameDidRenderStablyAction)
  }

  class Coordinator: CameraPreviewDisplayViewControllerDelegate {
    let frameDidSkippedAction: (Double) -> Void
    let frameDidRenderStablyAction: () -> Void

    init(frameDidSkippedAction: @escaping (Double) -> Void, frameDidRenderStablyAction: @escaping () -> Void) {
      self.frameDidSkippedAction = frameDidSkippedAction
      self.frameDidRenderStablyAction = frameDidRenderStablyAction
    }

    func frameDidSkipped(viewController: CameraPreviewDisplayViewController, diff: Double) {
      frameDidSkippedAction(diff)
    }

    func frameDidRenderStably(viewController: CameraPreviewDisplayViewController) {
      frameDidRenderStablyAction()
    }
  }
}
