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

  private func isClose(_ lhs: CGFloat, _ rhs: CGFloat, tolerance: CGFloat = 0.000_001) -> Bool {
    abs(lhs - rhs) <= tolerance
  }
}
