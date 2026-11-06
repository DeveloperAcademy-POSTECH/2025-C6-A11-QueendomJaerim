//
//  StrokeOverlayGeometryTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 6/21/26.
//

import CoreGraphics
import Testing

@testable import QueenCam

@Suite("StrokeOverlayGeometry Tests")
struct StrokeOverlayGeometryTests {
  @Test("정규화 좌표를 overlay rect 기준 절대 좌표로 변환한다")
  func convertsNormalizedPoint() {
    let point = StrokeOverlayGeometry.point(
      from: CGPoint(x: 0.25, y: 0.75),
      in: CGRect(x: 10, y: 20, width: 200, height: 400)
    )

    #expect(point == CGPoint(x: 60, y: 320))
  }

  // MARK: - 프리뷰 좌표 → 사진 좌표

  @Test("4:3과 1:1은 회전이 없으면 프리뷰 좌표가 그대로 사진 좌표다")
  func photoPointKeepsPreviewPointForFullRatios() {
    let point = CGPoint(x: 0.2, y: 0.9)

    #expect(StrokeOverlayGeometry.photoPoint(fromPreview: point, ratio: .ratio4x3, quarterTurns: 0) == point)
    #expect(StrokeOverlayGeometry.photoPoint(fromPreview: point, ratio: .ratio1x1, quarterTurns: 0) == point)
  }

  @Test("16:9는 화면에서 숨긴 위아래만큼 보정한다")
  func photoPointCompensatesHiddenBandForWideRatio() {
    let visibleHeight: CGFloat = 15.23 / 16
    let top = StrokeOverlayGeometry.photoPoint(fromPreview: CGPoint(x: 0, y: 0), ratio: .ratio16x9, quarterTurns: 0)
    let bottom = StrokeOverlayGeometry.photoPoint(fromPreview: CGPoint(x: 1, y: 1), ratio: .ratio16x9, quarterTurns: 0)

    #expect(isClose(top.x, 0))
    #expect(isClose(top.y, (1 - visibleHeight) / 2))
    #expect(isClose(bottom.x, 1))
    #expect(isClose(bottom.y, 1 - (1 - visibleHeight) / 2))
  }

  @Test("회전 수만큼 시계 방향으로 90도씩 돌린다")
  func photoPointRotatesClockwiseByQuarterTurns() {
    // 프리뷰 왼쪽 위 근처 점
    let point = CGPoint(x: 0.25, y: 0.1)

    let expected: [Int: CGPoint] = [
      0: CGPoint(x: 0.25, y: 0.1),
      1: CGPoint(x: 0.9, y: 0.25),
      2: CGPoint(x: 0.75, y: 0.9),
      3: CGPoint(x: 0.1, y: 0.75),
    ]

    for (turns, expectedPoint) in expected {
      let result = StrokeOverlayGeometry.photoPoint(fromPreview: point, ratio: .ratio4x3, quarterTurns: turns)
      #expect(isClose(result.x, expectedPoint.x) && isClose(result.y, expectedPoint.y), "turns \(turns): \(result)")
    }
  }

  @Test("16:9 보정 뒤에 회전한다")
  func photoPointCompensatesBeforeRotating() {
    let visibleHeight: CGFloat = 15.23 / 16
    let band = (1 - visibleHeight) / 2

    // 프리뷰 맨 위 가운데는 보정 뒤 (0.5, band)이고, 시계 방향 한 번 돌리면 (1 - band, 0.5)다.
    let result = StrokeOverlayGeometry.photoPoint(fromPreview: CGPoint(x: 0.5, y: 0), ratio: .ratio16x9, quarterTurns: 1)

    #expect(isClose(result.x, 1 - band))
    #expect(isClose(result.y, 0.5))
  }

  @Test("회전 수는 4로 나눈 나머지로 본다")
  func photoPointNormalizesQuarterTurns() {
    let point = CGPoint(x: 0.3, y: 0.6)
    let one = StrokeOverlayGeometry.photoPoint(fromPreview: point, ratio: .ratio4x3, quarterTurns: 1)

    #expect(StrokeOverlayGeometry.photoPoint(fromPreview: point, ratio: .ratio4x3, quarterTurns: 5) == one)
    #expect(StrokeOverlayGeometry.photoPoint(fromPreview: point, ratio: .ratio4x3, quarterTurns: -3) == one)
  }

  // MARK: - 촬영 각도 → 회전 수

  @Test("세로 화면 기준 각도 90은 회전이 없고, 90도씩 늘 때마다 한 번씩 돈다")
  func quarterTurnsFromVideoRotationAngle() {
    #expect(StrokeOverlayGeometry.quarterTurns(forVideoRotationAngle: 90) == 0)
    #expect(StrokeOverlayGeometry.quarterTurns(forVideoRotationAngle: 180) == 1)
    #expect(StrokeOverlayGeometry.quarterTurns(forVideoRotationAngle: 270) == 2)
    #expect(StrokeOverlayGeometry.quarterTurns(forVideoRotationAngle: 0) == 3)
  }

  @Test("90의 배수가 아닌 각도는 가장 가까운 방향으로 본다")
  func quarterTurnsFromNonRightAngle() {
    #expect(StrokeOverlayGeometry.quarterTurns(forVideoRotationAngle: 92) == 0)
    #expect(StrokeOverlayGeometry.quarterTurns(forVideoRotationAngle: 178) == 1)
  }

  // MARK: - 펜 두께 배율

  @Test("두께 배율은 사진 짧은 변을 프리뷰 폭으로 나눈 값이다")
  func lineScaleUsesShortSideOverPreviewWidth() {
    // 4:3 세로, 1:1, 16:9 세로, 가로 모두 짧은 변이 프리뷰 폭과 대응한다.
    let sizes: [(CGSize, CGFloat)] = [
      (CGSize(width: 3024, height: 4032), 3024),
      (CGSize(width: 3024, height: 3024), 3024),
      (CGSize(width: 2268, height: 4032), 2268),
      (CGSize(width: 4032, height: 2268), 2268),
    ]

    for (imageSize, shortSide) in sizes {
      let scale = StrokeOverlayGeometry.lineScale(imageSize: imageSize, previewWidth: 393)
      #expect(isClose(scale, shortSide / 393), "\(imageSize): \(scale)")
    }
  }

  @Test("프리뷰 폭이 없으면 두께 배율은 1이다")
  func lineScaleForInvalidPreviewWidth() {
    #expect(StrokeOverlayGeometry.lineScale(imageSize: CGSize(width: 3024, height: 4032), previewWidth: 0) == 1)
  }

  private func isClose(_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
    abs(lhs - rhs) < 0.000_001
  }
}
