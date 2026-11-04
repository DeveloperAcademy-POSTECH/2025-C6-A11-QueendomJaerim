//
//  PhotoOverlayCompositingServiceProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 6/21/26.
//

import Foundation

protocol PhotoOverlayCompositingServiceProtocol {
  /// `strokes`는 프리뷰 기준 좌표다. `previewWidth`는 펜을 그릴 때 화면에 있던 프리뷰 폭(pt)이고,
  /// `quarterTurns`는 셔터 순간 사진이 화면 기준으로 시계 방향 몇 번 돌아 저장됐는지다.
  func composite(
    photoOutput: PhotoOuput,
    strokes: [DrawableStroke],
    aspectRatio: PhotoAspectRatio,
    previewWidth: CGFloat,
    quarterTurns: Int
  ) -> PhotoOuput
}
