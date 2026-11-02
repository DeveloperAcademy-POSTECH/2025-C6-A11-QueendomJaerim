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
  // Figma 16:9는 다이내믹 아일랜드를 피해 안전 영역 위 끝보다 6 위에서 시작한다.
  static let widePreviewTopOffset: CGFloat = -6

  static var previewTopOffset: CGFloat {
    topToolBarTopInset + topToolBarHeight + previewTopSpacing
  }

  /// iPad처럼 넓은 화면에서는 높이 안에 들어오도록 줄인다.
  func previewWidth(in safeAreaSize: CGSize) -> CGFloat {
    min(safeAreaSize.width, (safeAreaSize.height - Self.previewTopOffset) * 3 / 4)
  }

  func previewTop(previewWidth: CGFloat, ratio: PhotoAspectRatio) -> CGFloat {
    guard ratio != .ratio16x9 else { return Self.widePreviewTopOffset }

    let baseHeight = PhotoAspectRatioGeometry.previewSize(width: previewWidth, ratio: .ratio4x3).height
    let height = PhotoAspectRatioGeometry.previewSize(width: previewWidth, ratio: ratio).height
    return Self.previewTopOffset + (baseHeight - height) / 2
  }

  func topToolBarOverlap(previewTop: CGFloat) -> CGFloat {
    max(0, Self.topToolBarTopInset + Self.topToolBarHeight - previewTop)
  }
}
