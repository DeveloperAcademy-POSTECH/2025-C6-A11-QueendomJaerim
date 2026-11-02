//
//  CameraView+PreviewLayout.swift
//  QueenCam
//
//  Created by seungchan on 11/2/26.
//

import SwiftUI

extension CameraView {
  static let topToolBarTopInset: CGFloat = 6
  static let topToolBarHeight: CGFloat = 34
  static let previewTopSpacing: CGFloat = 16
  static let bottomContainerBottomInset: CGFloat = 8

  static var previewTopOffset: CGFloat {
    topToolBarTopInset + topToolBarHeight + previewTopSpacing
  }

  /// iPad처럼 넓은 화면에서는 높이 안에 들어오도록 줄인다.
  func previewWidth(in safeAreaSize: CGSize) -> CGFloat {
    min(safeAreaSize.width, (safeAreaSize.height - Self.previewTopOffset) * 3 / 4)
  }

  func previewCenterY(previewWidth: CGFloat) -> CGFloat {
    let height = PhotoAspectRatioGeometry.previewSize(width: previewWidth, ratio: .ratio4x3).height
    return Self.previewTopOffset + height / 2
  }

  func topToolBarOverlap(previewWidth: CGFloat, previewHeight: CGFloat) -> CGFloat {
    let previewTop = previewCenterY(previewWidth: previewWidth) - previewHeight / 2
    return max(0, Self.topToolBarTopInset + Self.topToolBarHeight - previewTop)
  }
}
