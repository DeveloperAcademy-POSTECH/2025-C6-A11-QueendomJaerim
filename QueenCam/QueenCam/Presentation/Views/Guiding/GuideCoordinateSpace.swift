//
//  GuideCoordinateSpace.swift
//  QueenCam
//
//  Created by seungchan on 11/27/26.
//

import SwiftUI

/// 가이드(펜·프레임) 좌표의 기준인 4:3 프리뷰 영역을 4:3·1:1이 공유하는 가운데에 놓는 컨테이너.
/// 안쪽 뷰는 예전처럼 자기 크기의 몇 %로 그리면 되고, 프리뷰가 4:3보다 짧으면 넘친 부분은 바깥에서 잘린다.
struct GuideCoordinateSpace<Content: View>: View {
  @Environment(\.guideAspectRatio) private var ratio
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    GeometryReader { geo in
      let layout = GuideLayout(previewSize: geo.size, ratio: ratio)

      content
        .frame(width: layout.box.width, height: layout.box.height)
        .environment(\.guideOverdraw, layout.overdraw)
        .position(x: geo.size.width / 2, y: layout.centerY)
    }
  }
}

/// 프리뷰 안에서 가이드 영역(4:3)이 놓이는 자리
struct GuideLayout {
  let box: CGSize
  /// 프리뷰 안에서 가이드 영역 가운데의 세로 위치
  let centerY: CGFloat
  /// 프리뷰가 가이드 영역보다 위·아래로 더 길 때 더 그려야 하는 높이
  let overdraw: GuideOverdraw

  init(previewSize: CGSize, ratio: PhotoAspectRatio) {
    box = PhotoAspectRatioGeometry.previewSize(width: previewSize.width, ratio: .ratio4x3)
    centerY = previewSize.height / 2 + PhotoAspectRatioGeometry.guideCenterOffset(previewWidth: previewSize.width, ratio: ratio)
    overdraw = GuideOverdraw(
      top: max(0, centerY - box.height / 2),
      bottom: max(0, previewSize.height - (centerY + box.height / 2))
    )
  }

  /// 프리뷰 안의 터치 위치를 가이드 영역 기준 정규화 좌표로 바꾼다.
  func guidePoint(from location: CGPoint) -> CGPoint {
    guard box.width > 0, box.height > 0 else { return .zero }

    return CGPoint(
      x: location.x / box.width,
      y: (location.y - (centerY - box.height / 2)) / box.height
    )
  }
}

struct GuideOverdraw: Equatable {
  var top: CGFloat = 0
  var bottom: CGFloat = 0
}

private struct GuideOverdrawKey: EnvironmentKey {
  static let defaultValue = GuideOverdraw()
}

private struct GuideAspectRatioKey: EnvironmentKey {
  static let defaultValue = PhotoAspectRatio.ratio4x3
}

extension EnvironmentValues {
  var guideOverdraw: GuideOverdraw {
    get { self[GuideOverdrawKey.self] }
    set { self[GuideOverdrawKey.self] = newValue }
  }

  /// 지금 촬영 비율. 가이드 영역을 놓는 가운데 위치가 비율마다 조금 달라서 필요하다.
  var guideAspectRatio: PhotoAspectRatio {
    get { self[GuideAspectRatioKey.self] }
    set { self[GuideAspectRatioKey.self] = newValue }
  }
}

/// 가이드 영역 크기를 기준으로 그리되, 프리뷰가 더 길면 그 위아래 띠에도 그려지는 `Canvas`.
/// `Canvas`는 자기 크기 밖에는 그리지 못해서 위아래로 넓힌 뒤 그림 위치를 같은 만큼 내린다.
struct GuideCanvas: View {
  @Environment(\.guideOverdraw) private var overdraw
  private let render: (inout GraphicsContext, CGSize) -> Void

  init(render: @escaping (inout GraphicsContext, CGSize) -> Void) {
    self.render = render
  }

  var body: some View {
    Canvas { context, size in
      context.translateBy(x: 0, y: overdraw.top)
      render(&context, CGSize(width: size.width, height: size.height - overdraw.top - overdraw.bottom))
    }
    .padding(.top, -overdraw.top)
    .padding(.bottom, -overdraw.bottom)
  }
}
