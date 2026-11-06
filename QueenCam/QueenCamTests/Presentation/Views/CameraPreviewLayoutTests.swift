//
//  CameraPreviewLayoutTests.swift
//  QueenCamTests
//
//  Created by seungchan on 11/4/26.
//

import CoreGraphics
import Testing

@testable import QueenCam

@MainActor
@Suite("CameraView 프리뷰 배치 Tests")
struct CameraPreviewLayoutTests {
  // 안전 영역 크기
  private let iPhoneSE = CGSize(width: 375, height: 647)
  private let iPhoneMini = CGSize(width: 375, height: 728)
  private let iPhone16 = CGSize(width: 393, height: 759)
  private let iPhone16e = CGSize(width: 390, height: 763)

  // MARK: - 가이드 도구 모음 위치

  @Test("16:9는 모든 기기에서 가이드 도구 모음을 프리뷰 안에 둔다")
  func wideRatioAlwaysInPreview() {
    for size in [iPhoneSE, iPhoneMini, iPhone16, iPhone16e] {
      #expect(CameraView.isGuidingToolBarInPreview(ratio: .ratio16x9, safeAreaSize: size))
    }
  }

  @Test("4:3 프리뷰 아래에 가로 도구 모음 자리가 있으면 4:3·1:1은 가로 도구 모음을 쓴다")
  func longScreenUsesHorizontalToolBar() {
    for size in [iPhoneMini, iPhone16, iPhone16e] {
      #expect(!CameraView.isGuidingToolBarInPreview(ratio: .ratio4x3, safeAreaSize: size))
      #expect(!CameraView.isGuidingToolBarInPreview(ratio: .ratio1x1, safeAreaSize: size))
    }
  }

  @Test("SE처럼 4:3 프리뷰가 가로 도구 모음 자리를 덮으면 4:3·1:1도 프리뷰 안에 둔다")
  func shortScreenMovesToolBarIntoPreview() {
    #expect(CameraView.isGuidingToolBarInPreview(ratio: .ratio4x3, safeAreaSize: iPhoneSE))
    #expect(CameraView.isGuidingToolBarInPreview(ratio: .ratio1x1, safeAreaSize: iPhoneSE))
  }

  // MARK: - 프리뷰 안 아래 버튼을 올릴 높이

  @Test("프리뷰가 촬영 줄 위에서 끝나면 올리지 않는다")
  func noOverlapAboveCaptureRow() {
    // SE 4:3 아래 끝 556, 촬영 줄 위 끝 559
    #expect(CameraView.bottomControlsOverlap(previewBottom: 556, safeAreaHeight: iPhoneSE.height) == 0)
    // iPhone 16 16:9 아래 끝 약 659, 촬영 줄 위 끝 671
    let wideBottom = -6 + 393 * 15.23 / 9
    #expect(CameraView.bottomControlsOverlap(previewBottom: wideBottom, safeAreaHeight: iPhone16.height) == 0)
  }

  @Test("프리뷰가 촬영 줄 아래까지 내려오면 겹친 만큼 올린다")
  func overlapBelowCaptureRow() {
    // SE 16:9 아래 끝 약 628.6, 촬영 줄 위 끝 559
    let wideBottom = -6 + 375 * 15.23 / 9
    let overlap = CameraView.bottomControlsOverlap(previewBottom: wideBottom, safeAreaHeight: iPhoneSE.height)
    #expect(abs(overlap - (wideBottom - 559)) < 0.001)
  }
}
