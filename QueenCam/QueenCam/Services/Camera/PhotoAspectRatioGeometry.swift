//
//  PhotoAspectRatioGeometry.swift
//  QueenCam
//
//  Created by seungchan on 10/23/26.
//

import CoreGraphics

/// 프리뷰 표시·저장 크롭·가이드 좌표가 함께 쓰는 비율 계산 규칙.
/// 프리뷰 관련 값은 세로 화면 기준이며, 좌표는 0~1로 정규화한다.
nonisolated enum PhotoAspectRatioGeometry {
  /// 16:9 프리뷰는 저장 비율보다 세로를 약 5% 줄인 15.23:9 영역에 표시한다.
  private static let widePreviewLongSide: CGFloat = 15.23
  /// 4:3·1:1 프리뷰의 위 끝(안전 영역 기준). `CameraView.previewTopOffset`과 같은 값이다.
  private static let guideAreaTopOffset: CGFloat = 56
  /// 16:9 프리뷰의 위 끝. `CameraView.widePreviewTopOffset`과 같은 값이다.
  private static let widePreviewTopOffset: CGFloat = -6
  /// 세션 프리셋 `.photo`의 세로 영상은 너비:높이 3:4다.
  private static let cameraFeedHeightPerWidth: CGFloat = 4.0 / 3.0
  /// 잘린 사진의 크기가 비율과 맞는지 볼 때 허용하는 상대 오차
  private static let matchTolerance: CGFloat = 0.01

  /// 프리뷰 너비에 대한 비율별 표시 크기
  static func previewSize(width: CGFloat, ratio: PhotoAspectRatio) -> CGSize {
    guard width.isFinite, width > 0 else { return .zero }

    return CGSize(width: width, height: width * previewLongSide(for: ratio) / CGFloat(ratio.shortSide))
  }

  /// 저장될 사진의 너비가 프리뷰 너비와 같아지도록 키운 카메라 영상 크기
  static func cameraFeedSize(previewWidth: CGFloat, ratio: PhotoAspectRatio) -> CGSize {
    guard previewWidth.isFinite, previewWidth > 0 else { return .zero }

    let outputHeightPerWidth = CGFloat(ratio.longSide) / CGFloat(ratio.shortSide)
    let outputWidthInFeed = min(1, cameraFeedHeightPerWidth / outputHeightPerWidth)
    let feedWidth = previewWidth / outputWidthInFeed

    return CGSize(width: feedWidth, height: feedWidth * cameraFeedHeightPerWidth)
  }

  /// 프리뷰에 보이는 범위를 세로 저장 이미지 기준 정규화 영역으로 나타낸다.
  /// 16:9는 위아래를 같은 양만큼 숨기므로 가운데 띠만 보인다.
  static func visibleOutputRect(for ratio: PhotoAspectRatio) -> CGRect {
    let visibleHeight = previewLongSide(for: ratio) / CGFloat(ratio.longSide)

    return CGRect(x: 0, y: (1 - visibleHeight) / 2, width: 1, height: visibleHeight)
  }

  /// 프리뷰 정규화 좌표를 세로 저장 이미지의 정규화 좌표로 변환한다. 범위 밖 좌표도 같은 규칙으로 변환한다.
  static func outputPoint(fromPreview point: CGPoint, ratio: PhotoAspectRatio) -> CGPoint {
    let visibleRect = visibleOutputRect(for: ratio)

    return CGPoint(
      x: visibleRect.minX + point.x * visibleRect.width,
      y: visibleRect.minY + point.y * visibleRect.height
    )
  }

  /// 가이드(펜·프레임) 좌표를 4:3 프리뷰 영역 기준으로 저장하고, 그릴 때 현재 프리뷰 영역으로 바꾼다.
  /// 세 비율의 프리뷰 영역은 폭과 가운데가 같아서, 가운데 기준으로 세로만 배율을 곱하면 그린 자리와 크기가 그대로 남는다.
  /// 현재 프리뷰 밖에 걸친 좌표는 0 미만·1 초과 값으로 남는다.
  static func previewPoint(fromGuide point: CGPoint, ratio: PhotoAspectRatio) -> CGPoint {
    CGPoint(x: point.x, y: 0.5 + (point.y - 0.5) * guideToPreviewScale(ratio: ratio))
  }

  /// `previewPoint(fromGuide:ratio:)`의 반대 방향. 현재 프리뷰 정규화 좌표를 저장용 가이드 좌표로 바꾼다.
  static func guidePoint(fromPreview point: CGPoint, ratio: PhotoAspectRatio) -> CGPoint {
    CGPoint(x: point.x, y: 0.5 + (point.y - 0.5) / guideToPreviewScale(ratio: ratio))
  }

  static func previewRect(fromGuide rect: CGRect, ratio: PhotoAspectRatio) -> CGRect {
    let scale = guideToPreviewScale(ratio: ratio)

    return CGRect(x: rect.minX, y: 0.5 + (rect.minY - 0.5) * scale, width: rect.width, height: rect.height * scale)
  }

  static func guideRect(fromPreview rect: CGRect, ratio: PhotoAspectRatio) -> CGRect {
    let scale = guideToPreviewScale(ratio: ratio)

    return CGRect(x: rect.minX, y: 0.5 + (rect.minY - 0.5) / scale, width: rect.width, height: rect.height / scale)
  }

  /// 가이드 영역(4:3·1:1이 공유하는 가운데)이 지금 프리뷰 가운데보다 아래로 얼마나 내려가 있는지(pt). 음수면 위에 있다.
  /// 4:3과 1:1은 가운데가 같지만, 16:9는 Figma 배치가 위 끝 -6에서 시작해 가운데가 약 8.5pt 아래에 있다.
  /// 가이드를 화면에서 그린 자리에 두려면 이 차이만큼 가이드 영역을 옮긴다.
  static func guideCenterOffset(previewWidth: CGFloat, ratio: PhotoAspectRatio) -> CGFloat {
    guard ratio == .ratio16x9, previewWidth.isFinite, previewWidth > 0 else { return 0 }

    let guideHeight = previewSize(width: previewWidth, ratio: .ratio4x3).height
    let previewHeight = previewSize(width: previewWidth, ratio: ratio).height
    return (guideAreaTopOffset + guideHeight / 2) - (widePreviewTopOffset + previewHeight / 2)
  }

  /// `previewPoint(fromGuide:ratio:)`에 가운데 차이(`guideCenterOffset`)까지 반영한 값
  static func previewPoint(fromGuide point: CGPoint, ratio: PhotoAspectRatio, previewWidth: CGFloat) -> CGPoint {
    let base = previewPoint(fromGuide: point, ratio: ratio)
    let height = previewSize(width: previewWidth, ratio: ratio).height
    guard height > 0 else { return base }

    return CGPoint(x: base.x, y: base.y + guideCenterOffset(previewWidth: previewWidth, ratio: ratio) / height)
  }

  /// 지금 프리뷰에 보이는 범위를 가이드 좌표로 나타낸 영역(가운데 차이 반영)
  static func visibleGuideBounds(ratio: PhotoAspectRatio, previewWidth: CGFloat) -> CGRect {
    let bounds = guideRect(fromPreview: CGRect(x: 0, y: 0, width: 1, height: 1), ratio: ratio)
    let guideHeight = previewSize(width: previewWidth, ratio: .ratio4x3).height
    guard guideHeight > 0 else { return bounds }

    let shift = guideCenterOffset(previewWidth: previewWidth, ratio: ratio) / guideHeight
    return CGRect(x: bounds.minX, y: bounds.minY - shift, width: bounds.width, height: bounds.height)
  }

  /// 이미지 크기가 비율대로 잘린 크기인지 본다. 방향과 무관하게 긴 변÷짧은 변을 비교하고, 반올림 차이를 위해 1%까지 허용한다.
  /// 세 비율의 긴 변÷짧은 변(1, 1.78, 1.33)은 서로 25% 넘게 떨어져 있어 다른 비율과 헷갈리지 않는다.
  static func matches(imageSize: CGSize, ratio: PhotoAspectRatio) -> Bool {
    guard
      imageSize.width.isFinite, imageSize.height.isFinite,
      imageSize.width >= 1, imageSize.height >= 1
    else { return false }

    let imageRatio = max(imageSize.width, imageSize.height) / min(imageSize.width, imageSize.height)
    let expectedRatio = CGFloat(ratio.longSide) / CGFloat(ratio.shortSide)

    return abs(imageRatio - expectedRatio) / expectedRatio <= matchTolerance
  }

  /// 방향이 적용된 이미지에서 비율에 맞는 가장 큰 중앙 영역을 정수 픽셀로 구한다.
  /// 긴 변의 방향은 이미지를 따른다. 세로 이미지의 16:9는 9:16으로 자른다.
  static func centerCropRect(imageSize: CGSize, ratio: PhotoAspectRatio) -> CGRect? {
    guard
      imageSize.width.isFinite, imageSize.height.isFinite,
      imageSize.width >= 1, imageSize.height >= 1
    else { return nil }

    let imageWidth = Int(imageSize.width)
    let imageHeight = Int(imageSize.height)

    let isPortrait = imageHeight >= imageWidth
    let ratioWidth = isPortrait ? ratio.shortSide : ratio.longSide
    let ratioHeight = isPortrait ? ratio.longSide : ratio.shortSide

    // 실수 나눗셈 오차로 1픽셀이 줄지 않도록 정수로 계산한다.
    let cropWidth: Int
    let cropHeight: Int
    if imageWidth * ratioHeight > imageHeight * ratioWidth {
      cropWidth = imageHeight * ratioWidth / ratioHeight
      cropHeight = imageHeight
    } else {
      cropWidth = imageWidth
      cropHeight = imageWidth * ratioHeight / ratioWidth
    }

    guard cropWidth > 0, cropHeight > 0 else { return nil }

    return CGRect(
      x: (imageWidth - cropWidth) / 2,
      y: (imageHeight - cropHeight) / 2,
      width: cropWidth,
      height: cropHeight
    )
  }
}

nonisolated private extension PhotoAspectRatioGeometry {
  /// 가이드 좌표의 세로 1은 4:3 프리뷰 높이다. 그 값을 현재 프리뷰 높이에 대한 비율로 바꾸는 배율이다.
  static func guideToPreviewScale(ratio: PhotoAspectRatio) -> CGFloat {
    let guideHeightPerWidth = previewLongSide(for: .ratio4x3) / CGFloat(PhotoAspectRatio.ratio4x3.shortSide)
    let previewHeightPerWidth = previewLongSide(for: ratio) / CGFloat(ratio.shortSide)

    return guideHeightPerWidth / previewHeightPerWidth
  }

  static func previewLongSide(for ratio: PhotoAspectRatio) -> CGFloat {
    ratio == .ratio16x9 ? widePreviewLongSide : CGFloat(ratio.longSide)
  }
}
