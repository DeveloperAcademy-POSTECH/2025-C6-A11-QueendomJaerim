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
  @Test("3:4 캔버스를 넓은 이미지 중앙에 aspect-fit한다")
  func aspectFitRectInWideImage() {
    let rect = StrokeOverlayGeometry.aspectFitRect(
      in: CGRect(x: 0, y: 0, width: 400, height: 400)
    )

    #expect(rect == CGRect(x: 50, y: 0, width: 300, height: 400))
  }

  @Test("정규화 좌표를 overlay rect 기준 절대 좌표로 변환한다")
  func convertsNormalizedPoint() {
    let point = StrokeOverlayGeometry.point(
      from: CGPoint(x: 0.25, y: 0.75),
      in: CGRect(x: 10, y: 20, width: 200, height: 400)
    )

    #expect(point == CGPoint(x: 60, y: 320))
  }
}
