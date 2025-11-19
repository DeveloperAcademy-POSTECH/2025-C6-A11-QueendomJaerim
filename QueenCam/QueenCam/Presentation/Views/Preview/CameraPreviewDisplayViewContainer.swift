//
//  CameraPreviewMTKViewContainer.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Combine
import CoreMedia
import Foundation
import SwiftUI

struct CameraPreviewDisplayViewContainer: UIViewControllerRepresentable {
  /// 현재 프레임 버퍼
  var currentSampleBuffer: CMSampleBuffer?

  /// 좌우 반전 여부 (셀피 모드일 때 반전)
  var isInversed: Bool

  /// 렌더링이 불안정하여 프레임이 스킵되었을 때 실행할 클로져
  let frameDidSkippedAction: () -> Void

  /// 렌더링이 안정적일 때 실행할 클로져
  let frameDidRenderStablyAction: () -> Void

  func makeUIViewController(context: Context) -> CameraPreviewDisplayViewController {
    CameraPreviewDisplayViewController()
  }

  func updateUIViewController(_ uiViewController: CameraPreviewDisplayViewController, context: Context) {
    uiViewController.renderFrame(sampleBuffer: currentSampleBuffer)
    uiViewController.delegate = context.coordinator
    uiViewController.isInversed = isInversed
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(frameDidSkippedAction: frameDidSkippedAction, frameDidRenderStablyAction: frameDidRenderStablyAction)
  }

  class Coordinator: CameraPreviewDisplayViewControllerDelegate {
    let frameDidSkippedAction: () -> Void
    let frameDidRenderStablyAction: () -> Void

    init(frameDidSkippedAction: @escaping () -> Void, frameDidRenderStablyAction: @escaping () -> Void) {
      self.frameDidSkippedAction = frameDidSkippedAction
      self.frameDidRenderStablyAction = frameDidRenderStablyAction
    }

    func frameDidSkipped(viewController: CameraPreviewDisplayViewController) {
      frameDidSkippedAction()
    }

    func frameDidRenderStably(viewController: CameraPreviewDisplayViewController) {
      frameDidRenderStablyAction()
    }
  }
}
