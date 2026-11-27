//
//  PhotoAspectRatioGeometryTests.swift
//  QueenCamTests
//
//  Created by seungchan on 10/23/26.
//

import CoreGraphics
import Testing

@testable import QueenCam

@Suite("PhotoAspectRatioGeometry Tests")
struct PhotoAspectRatioGeometryTests {
  // 16:9 프리뷰에 보이는 저장 이미지 높이 비율 15.23 / 16
  private let wideVisibleHeight: CGFloat = 15.23 / 16

  // MARK: - 프리뷰 표시 크기

  @Test("프리뷰 너비로 비율별 세로 화면 표시 크기를 계산한다")
  func previewSizeByRatio() {
    let width: CGFloat = 390

    #expect(PhotoAspectRatioGeometry.previewSize(width: width, ratio: .ratio4x3) == CGSize(width: 390, height: 520))
    #expect(PhotoAspectRatioGeometry.previewSize(width: width, ratio: .ratio1x1) == CGSize(width: 390, height: 390))

    let wide = PhotoAspectRatioGeometry.previewSize(width: width, ratio: .ratio16x9)
    #expect(wide.width == 390)
    #expect(isClose(wide.height, 390 * 15.23 / 9))
  }

  @Test("너비가 0 이하이면 크기 0을 반환한다")
  func previewSizeForInvalidWidth() {
    #expect(PhotoAspectRatioGeometry.previewSize(width: 0, ratio: .ratio4x3) == .zero)
    #expect(PhotoAspectRatioGeometry.previewSize(width: -10, ratio: .ratio16x9) == .zero)
  }

  // MARK: - 가이드 좌표(4:3 프리뷰 영역 기준)

  @Test("4:3에서는 가이드 좌표와 프리뷰 좌표가 같다")
  func guideAndPreviewAreSameOn4x3() {
    let point = CGPoint(x: 0.3, y: 0.8)

    #expect(PhotoAspectRatioGeometry.previewPoint(fromGuide: point, ratio: .ratio4x3) == point)
    #expect(PhotoAspectRatioGeometry.guidePoint(fromPreview: point, ratio: .ratio4x3) == point)
  }

  @Test("가이드 좌표의 가운데는 어느 비율에서도 프리뷰 가운데다")
  func guideCenterStaysCentered() {
    for ratio in PhotoAspectRatio.allCases {
      let point = PhotoAspectRatioGeometry.previewPoint(fromGuide: CGPoint(x: 0.5, y: 0.5), ratio: ratio)

      #expect(isClose(point.x, 0.5))
      #expect(isClose(point.y, 0.5))
    }
  }

  @Test("1:1 프리뷰는 4:3 프리뷰보다 짧아 4:3 맨 위 좌표가 프리뷰 밖(0 미만)에 놓인다")
  func guidePointOutsideShorterPreview() {
    // 4:3 높이 520pt, 1:1 높이 390pt, 폭 390pt 기준. 4:3 맨 위(y=0)는 가운데에서 260pt 위, 1:1 프리뷰는 가운데에서 195pt까지다.
    let top = PhotoAspectRatioGeometry.previewPoint(fromGuide: CGPoint(x: 0.4, y: 0), ratio: .ratio1x1)

    #expect(isClose(top.x, 0.4))
    #expect(isClose(top.y, 0.5 - 260.0 / 390.0))
    #expect(top.y < 0)
  }

  @Test("16:9 프리뷰는 4:3보다 길어 4:3 영역이 프리뷰 안쪽에 들어온다")
  func guidePointInsideLongerPreview() {
    let top = PhotoAspectRatioGeometry.previewPoint(fromGuide: CGPoint(x: 0.4, y: 0), ratio: .ratio16x9)
    let wideHeight = 390 * 15.23 / 9

    #expect(isClose(top.y, 0.5 - 260.0 / wideHeight))
    #expect(top.y > 0)
  }

  @Test("화면에서 그린 자리의 크기는 비율을 바꿔도 같다(폭 390pt 기준 pt로 환산)")
  func drawnSizeStaysSameInPoints() {
    let width: CGFloat = 390
    let guideTop = CGPoint(x: 0.2, y: 0.4)
    let guideBottom = CGPoint(x: 0.2, y: 0.6)
    let guideHeightInPoints = (guideBottom.y - guideTop.y) * 520

    for ratio in PhotoAspectRatio.allCases {
      let height = PhotoAspectRatioGeometry.previewSize(width: width, ratio: ratio).height
      let top = PhotoAspectRatioGeometry.previewPoint(fromGuide: guideTop, ratio: ratio)
      let bottom = PhotoAspectRatioGeometry.previewPoint(fromGuide: guideBottom, ratio: ratio)

      #expect(isClose((bottom.y - top.y) * height, guideHeightInPoints))
    }
  }

  @Test("가이드 좌표와 프리뷰 좌표는 세 비율 모두 왕복하면 원래 값으로 돌아온다")
  func guidePointRoundTrip() {
    let points = [CGPoint(x: 0, y: -0.2), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1, y: 1.3)]

    for ratio in PhotoAspectRatio.allCases {
      for point in points {
        let preview = PhotoAspectRatioGeometry.previewPoint(fromGuide: point, ratio: ratio)
        let back = PhotoAspectRatioGeometry.guidePoint(fromPreview: preview, ratio: ratio)

        #expect(isClose(back.x, point.x))
        #expect(isClose(back.y, point.y))
      }
    }
  }

  @Test("가이드 영역(프레임)도 같은 규칙으로 변환되고 왕복하면 원래 값으로 돌아온다")
  func guideRectConversion() {
    let rect = CGRect(x: 0.24, y: 0.15, width: 0.55, height: 0.69)

    let same = PhotoAspectRatioGeometry.previewRect(fromGuide: rect, ratio: .ratio4x3)
    #expect(isClose(same.minY, rect.minY))
    #expect(isClose(same.height, rect.height))

    for ratio in PhotoAspectRatio.allCases {
      let preview = PhotoAspectRatioGeometry.previewRect(fromGuide: rect, ratio: ratio)
      let back = PhotoAspectRatioGeometry.guideRect(fromPreview: preview, ratio: ratio)

      #expect(isClose(preview.width, rect.width))
      #expect(isClose(back.minY, rect.minY))
      #expect(isClose(back.height, rect.height))
    }

    // 1:1에서 높이는 4:3 높이의 390/520 배가 아니라 520/390 배로 커진다(프리뷰가 짧아 정규화 값이 커진다).
    let square = PhotoAspectRatioGeometry.previewRect(fromGuide: rect, ratio: .ratio1x1)
    #expect(isClose(square.height, rect.height * 520.0 / 390.0))
  }

  @Test("16:9만 가이드 영역 가운데가 프리뷰 가운데보다 약 8pt 위에 있고, 4:3·1:1은 같다")
  func guideCenterOffsetOnlyOnWideRatio() {
    #expect(PhotoAspectRatioGeometry.guideCenterOffset(previewWidth: 390, ratio: .ratio4x3) == 0)
    #expect(PhotoAspectRatioGeometry.guideCenterOffset(previewWidth: 390, ratio: .ratio1x1) == 0)

    // 가이드 가운데 = 56 + 520/2 = 316, 16:9 프리뷰 가운데 = -6 + (390 * 15.23 / 9) / 2
    let expected = 316 - (-6 + 390 * 15.23 / 9 / 2)
    #expect(isClose(PhotoAspectRatioGeometry.guideCenterOffset(previewWidth: 390, ratio: .ratio16x9), expected))
    #expect(expected < 0)
  }

  @Test("가운데 차이는 레이아웃 상수와 같은 값을 쓴다")
  func guideCenterOffsetUsesLayoutConstants() {
    #expect(CameraView.previewTopOffset == 56)
    #expect(CameraView.widePreviewTopOffset == -6)
  }

  @Test("16:9에서 가이드 가운데는 가운데 차이만큼 정규화 좌표가 어긋난다")
  func previewPointIncludesCenterOffsetOnWideRatio() {
    let width: CGFloat = 390
    let height = PhotoAspectRatioGeometry.previewSize(width: width, ratio: .ratio16x9).height
    let offset = PhotoAspectRatioGeometry.guideCenterOffset(previewWidth: width, ratio: .ratio16x9)

    let center = PhotoAspectRatioGeometry.previewPoint(fromGuide: CGPoint(x: 0.5, y: 0.5), ratio: .ratio16x9, previewWidth: width)
    #expect(isClose(center.y, 0.5 + offset / height))

    let same = PhotoAspectRatioGeometry.previewPoint(fromGuide: CGPoint(x: 0.5, y: 0.2), ratio: .ratio1x1, previewWidth: width)
    #expect(isClose(same.y, PhotoAspectRatioGeometry.previewPoint(fromGuide: CGPoint(x: 0.5, y: 0.2), ratio: .ratio1x1).y))
  }

  @Test("보이는 가이드 범위는 16:9에서 가운데 차이만큼 이동한다")
  func visibleGuideBoundsShiftOnWideRatio() {
    let width: CGFloat = 390
    let plain = PhotoAspectRatioGeometry.guideRect(fromPreview: CGRect(x: 0, y: 0, width: 1, height: 1), ratio: .ratio16x9)
    let bounds = PhotoAspectRatioGeometry.visibleGuideBounds(ratio: .ratio16x9, previewWidth: width)
    let offset = PhotoAspectRatioGeometry.guideCenterOffset(previewWidth: width, ratio: .ratio16x9)

    #expect(isClose(bounds.height, plain.height))
    #expect(isClose(bounds.minY, plain.minY - offset / 520))
    let square = PhotoAspectRatioGeometry.visibleGuideBounds(ratio: .ratio1x1, previewWidth: width)
    let squarePlain = PhotoAspectRatioGeometry.guideRect(fromPreview: CGRect(x: 0, y: 0, width: 1, height: 1), ratio: .ratio1x1)
    #expect(square == squarePlain)
  }

  // MARK: - 프리뷰에 보이는 저장 범위

  @Test("4:3과 1:1은 저장 이미지 전체가 프리뷰에 보인다")
  func fullVisibleRect() {
    let full = CGRect(x: 0, y: 0, width: 1, height: 1)

    #expect(PhotoAspectRatioGeometry.visibleOutputRect(for: .ratio4x3) == full)
    #expect(PhotoAspectRatioGeometry.visibleOutputRect(for: .ratio1x1) == full)
  }

  @Test("16:9는 저장 이미지의 위아래를 같은 양만큼 뺀 가운데 띠가 보인다")
  func wideVisibleRect() {
    let rect = PhotoAspectRatioGeometry.visibleOutputRect(for: .ratio16x9)

    #expect(rect.minX == 0)
    #expect(rect.width == 1)
    #expect(isClose(rect.height, wideVisibleHeight))
    #expect(isClose(rect.minY, (1 - wideVisibleHeight) / 2))
    #expect(isClose(rect.midY, 0.5))
  }

  // MARK: - 프리뷰 좌표 → 저장 이미지 좌표

  @Test("4:3과 1:1은 프리뷰 좌표가 저장 이미지 좌표와 같다")
  func outputPointIsIdentityForFullVisibleRatios() {
    let point = CGPoint(x: 0.25, y: 0.8)

    #expect(PhotoAspectRatioGeometry.outputPoint(fromPreview: point, ratio: .ratio4x3) == point)
    #expect(PhotoAspectRatioGeometry.outputPoint(fromPreview: point, ratio: .ratio1x1) == point)
  }

  @Test("16:9는 프리뷰 위아래 끝이 저장 이미지의 가운데 띠 끝으로 옮겨지고 중앙은 유지된다")
  func outputPointForWideRatio() {
    let top = PhotoAspectRatioGeometry.outputPoint(fromPreview: CGPoint(x: 0.3, y: 0), ratio: .ratio16x9)
    let bottom = PhotoAspectRatioGeometry.outputPoint(fromPreview: CGPoint(x: 0.3, y: 1), ratio: .ratio16x9)
    let center = PhotoAspectRatioGeometry.outputPoint(fromPreview: CGPoint(x: 0.5, y: 0.5), ratio: .ratio16x9)

    #expect(top.x == 0.3)
    #expect(isClose(top.y, (1 - wideVisibleHeight) / 2))
    #expect(bottom.x == 0.3)
    #expect(isClose(bottom.y, (1 + wideVisibleHeight) / 2))
    #expect(isClose(center.x, 0.5))
    #expect(isClose(center.y, 0.5))
  }

  @Test("프리뷰 범위 밖 좌표도 자르지 않고 같은 규칙으로 변환한다")
  func outputPointOutsidePreview() {
    let point = PhotoAspectRatioGeometry.outputPoint(fromPreview: CGPoint(x: -0.1, y: 1.2), ratio: .ratio16x9)

    #expect(point.x == -0.1)
    #expect(isClose(point.y, (1 - wideVisibleHeight) / 2 + 1.2 * wideVisibleHeight))
  }

  // MARK: - 카메라 영상 표시 크기

  @Test("저장될 사진의 너비가 프리뷰 너비와 같도록 3:4 카메라 영상 크기를 정한다")
  func cameraFeedSizeByRatio() {
    let width: CGFloat = 393

    #expect(PhotoAspectRatioGeometry.cameraFeedSize(previewWidth: width, ratio: .ratio4x3) == CGSize(width: 393, height: 524))
    #expect(PhotoAspectRatioGeometry.cameraFeedSize(previewWidth: width, ratio: .ratio1x1) == CGSize(width: 393, height: 524))

    let wide = PhotoAspectRatioGeometry.cameraFeedSize(previewWidth: width, ratio: .ratio16x9)
    #expect(isClose(wide.width, 524))
    #expect(isClose(wide.height, 524 * 4 / 3))
  }

  @Test("프리뷰 너비가 0 이하이면 카메라 영상 크기 0을 반환한다")
  func cameraFeedSizeForInvalidWidth() {
    #expect(PhotoAspectRatioGeometry.cameraFeedSize(previewWidth: 0, ratio: .ratio4x3) == .zero)
    #expect(PhotoAspectRatioGeometry.cameraFeedSize(previewWidth: -10, ratio: .ratio16x9) == .zero)
  }

  @Test("카메라 영상에서 프리뷰에 보이는 범위가 저장 크롭과 보이는 범위 규칙에 맞다", arguments: PhotoAspectRatio.allCases)
  func cameraFeedMatchesCropAndVisibleRect(ratio: PhotoAspectRatio) throws {
    let imageSize = CGSize(width: 3024, height: 4032)
    let crop = try #require(PhotoAspectRatioGeometry.centerCropRect(imageSize: imageSize, ratio: ratio))
    let visibleRect = PhotoAspectRatioGeometry.visibleOutputRect(for: ratio)

    let feed = PhotoAspectRatioGeometry.cameraFeedSize(previewWidth: 393, ratio: ratio)
    let preview = PhotoAspectRatioGeometry.previewSize(width: 393, ratio: ratio)

    #expect(isClose(preview.width / feed.width, crop.width / imageSize.width))
    #expect(isClose(preview.height / feed.height, visibleRect.height * crop.height / imageSize.height))
  }

  // MARK: - 중앙 크롭

  @Test("세로 이미지를 비율별로 중앙에서 자른다")
  func centerCropPortraitImage() {
    let size = CGSize(width: 3024, height: 4032)

    #expect(
      PhotoAspectRatioGeometry.centerCropRect(imageSize: size, ratio: .ratio4x3)
        == CGRect(x: 0, y: 0, width: 3024, height: 4032)
    )
    #expect(
      PhotoAspectRatioGeometry.centerCropRect(imageSize: size, ratio: .ratio16x9)
        == CGRect(x: 378, y: 0, width: 2268, height: 4032)
    )
    #expect(
      PhotoAspectRatioGeometry.centerCropRect(imageSize: size, ratio: .ratio1x1)
        == CGRect(x: 0, y: 504, width: 3024, height: 3024)
    )
  }

  @Test("가로 이미지는 긴 변을 가로로 두고 중앙에서 자른다")
  func centerCropLandscapeImage() {
    let size = CGSize(width: 4032, height: 3024)

    #expect(
      PhotoAspectRatioGeometry.centerCropRect(imageSize: size, ratio: .ratio4x3)
        == CGRect(x: 0, y: 0, width: 4032, height: 3024)
    )
    #expect(
      PhotoAspectRatioGeometry.centerCropRect(imageSize: size, ratio: .ratio16x9)
        == CGRect(x: 0, y: 378, width: 4032, height: 2268)
    )
    #expect(
      PhotoAspectRatioGeometry.centerCropRect(imageSize: size, ratio: .ratio1x1)
        == CGRect(x: 504, y: 0, width: 3024, height: 3024)
    )
  }

  @Test("나누어떨어지지 않는 크기도 정수 픽셀 영역으로 자른다")
  func centerCropProducesIntegralRect() throws {
    let rect = try #require(
      PhotoAspectRatioGeometry.centerCropRect(imageSize: CGSize(width: 1001, height: 1335), ratio: .ratio16x9)
    )

    #expect(rect == rect.integral)
    #expect(rect.height == 1335)
    #expect(rect.width == 750)
    #expect(rect.minX == 125)
  }

  @Test("크기가 잘못되면 크롭 영역을 만들지 않는다")
  func centerCropForInvalidSize() {
    #expect(PhotoAspectRatioGeometry.centerCropRect(imageSize: .zero, ratio: .ratio1x1) == nil)
    #expect(PhotoAspectRatioGeometry.centerCropRect(imageSize: CGSize(width: -1, height: 10), ratio: .ratio4x3) == nil)
    #expect(
      PhotoAspectRatioGeometry.centerCropRect(imageSize: CGSize(width: CGFloat.infinity, height: 10), ratio: .ratio4x3)
        == nil
    )
  }

  // MARK: - 이미지가 비율대로 잘렸는지

  @Test("비율대로 잘린 세로 사진은 그 비율과 맞다")
  func matchesCroppedPortraitSizes() {
    #expect(PhotoAspectRatioGeometry.matches(imageSize: CGSize(width: 3024, height: 4032), ratio: .ratio4x3))
    #expect(PhotoAspectRatioGeometry.matches(imageSize: CGSize(width: 2268, height: 4032), ratio: .ratio16x9))
    #expect(PhotoAspectRatioGeometry.matches(imageSize: CGSize(width: 3024, height: 3024), ratio: .ratio1x1))
  }

  @Test("가로 사진도 긴 변과 짧은 변으로 비교한다")
  func matchesLandscapeSizes() {
    #expect(PhotoAspectRatioGeometry.matches(imageSize: CGSize(width: 4032, height: 3024), ratio: .ratio4x3))
    #expect(PhotoAspectRatioGeometry.matches(imageSize: CGSize(width: 4032, height: 2268), ratio: .ratio16x9))
  }

  @Test("자르지 않은 원본은 다른 비율과 맞지 않는다")
  func rejectsOtherRatios() {
    let original = CGSize(width: 3024, height: 4032)
    #expect(!PhotoAspectRatioGeometry.matches(imageSize: original, ratio: .ratio1x1))
    #expect(!PhotoAspectRatioGeometry.matches(imageSize: original, ratio: .ratio16x9))
    #expect(!PhotoAspectRatioGeometry.matches(imageSize: CGSize(width: 2268, height: 4032), ratio: .ratio4x3))
  }

  @Test("1% 안의 크기 차이는 맞다고 보고 그보다 크면 맞지 않는다")
  func toleratesSmallDifference() {
    // 2316 ÷ 1302 = 1.7788, 16:9 = 1.7778 (0.06% 차이)
    #expect(PhotoAspectRatioGeometry.matches(imageSize: CGSize(width: 1302, height: 2316), ratio: .ratio16x9))
    // 4032 ÷ 3000 = 1.344, 4:3 = 1.333 (0.8% 차이)
    #expect(PhotoAspectRatioGeometry.matches(imageSize: CGSize(width: 3000, height: 4032), ratio: .ratio4x3))
    // 4032 ÷ 2950 = 1.367 (2.5% 차이)
    #expect(!PhotoAspectRatioGeometry.matches(imageSize: CGSize(width: 2950, height: 4032), ratio: .ratio4x3))
  }

  @Test("크기가 잘못되면 맞지 않는다")
  func rejectsInvalidSize() {
    #expect(!PhotoAspectRatioGeometry.matches(imageSize: .zero, ratio: .ratio1x1))
    #expect(!PhotoAspectRatioGeometry.matches(imageSize: CGSize(width: CGFloat.infinity, height: 10), ratio: .ratio1x1))
  }

  private func isClose(_ lhs: CGFloat, _ rhs: CGFloat, tolerance: CGFloat = 0.000_001) -> Bool {
    abs(lhs - rhs) <= tolerance
  }
}
