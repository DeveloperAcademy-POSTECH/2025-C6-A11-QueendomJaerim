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
  // Figma 하단 조작부: 가로 가이드 도구 모음 57, 간격 18, 촬영 줄 80
  static let guidingToolBarHeight: CGFloat = 57
  static let bottomContainerSpacing: CGFloat = 18
  static let captureRowHeight: CGFloat = 80
  // Figma 16:9는 다이내믹 아일랜드를 피해 안전 영역 위 끝보다 6 위에서 시작한다.
  static let widePreviewTopOffset: CGFloat = -6

  static var previewTopOffset: CGFloat {
    topToolBarTopInset + topToolBarHeight + previewTopSpacing
  }

  /// iPad처럼 넓은 화면에서는 높이 안에 들어오도록 줄인다.
  static func previewWidth(in safeAreaSize: CGSize) -> CGFloat {
    min(safeAreaSize.width, (safeAreaSize.height - previewTopOffset) * 3 / 4)
  }

  /// SE처럼 4:3 프리뷰가 가로 가이드 도구 모음 자리를 덮는 화면에서는 1:1도 프리뷰 안에 둬서 비율마다 위치가 바뀌지 않게 한다.
  static func isGuidingToolBarInPreview(ratio: PhotoAspectRatio, safeAreaSize: CGSize) -> Bool {
    guard ratio != .ratio16x9 else { return true }

    let width = previewWidth(in: safeAreaSize)
    let baseBottom = previewTopOffset + PhotoAspectRatioGeometry.previewSize(width: width, ratio: .ratio4x3).height
    let toolBarTop = captureRowTop(safeAreaHeight: safeAreaSize.height) - bottomContainerSpacing - guidingToolBarHeight
    return baseBottom > toolBarTop
  }

  /// 프리뷰가 촬영 줄 뒤까지 내려오면 프리뷰 안 아래 버튼을 그만큼 올린다.
  static func bottomControlsOverlap(previewBottom: CGFloat, safeAreaHeight: CGFloat) -> CGFloat {
    max(0, previewBottom - captureRowTop(safeAreaHeight: safeAreaHeight))
  }

  private static func captureRowTop(safeAreaHeight: CGFloat) -> CGFloat {
    safeAreaHeight - bottomContainerBottomInset - captureRowHeight
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
