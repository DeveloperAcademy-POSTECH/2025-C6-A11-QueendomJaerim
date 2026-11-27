//
//  GuideCoordinateSpace.swift
//  QueenCam
//
//  Created by seungchan on 11/27/26.
//

import SwiftUI

/// 가이드(펜·프레임) 좌표의 기준인 4:3 프리뷰 영역을 현재 프리뷰 가운데에 놓는 컨테이너.
/// 안쪽 뷰는 예전처럼 자기 크기의 몇 %로 그리면 되고, 프리뷰가 4:3보다 짧으면 넘친 부분은 바깥에서 잘린다.
struct GuideCoordinateSpace<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    GeometryReader { geo in
      let box = PhotoAspectRatioGeometry.previewSize(width: geo.size.width, ratio: .ratio4x3)

      content
        .frame(width: box.width, height: box.height)
        .position(x: geo.size.width / 2, y: geo.size.height / 2)
    }
  }
}
