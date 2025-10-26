//
//  FrameLayerView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.

import SwiftUI

/// 한개의 프레임에 대한 모든 제스처 관리
struct FrameView: View {
  @Bindable var frameViewModel: FrameViewModel
  let frame: Frame
  let containerSize: CGSize
  var isSelected: Bool

  @State private var frameMove: CGRect? = nil
  @State private var frameScale: CGRect? = nil
  @State private var cornerScale: CGRect? = nil

  var body: some View {
    let rect = frame.rect
    let width = rect.width * containerSize.width
    let height = rect.height * containerSize.height
    let x = (rect.origin.x + rect.width / 2) * containerSize.width
    let y = (rect.origin.y + rect.height / 2) * containerSize.height

    //프레임 사격형 표시
    ZStack(alignment: .center) {
      Rectangle()
        .fill(frame.color)
        .overlay(Rectangle().stroke(isSelected ? .white : frame.color, lineWidth: 2))
        .frame(width: width, height: height)
        .position(x: x, y: y)
        .onTapGesture { frameViewModel.selectFrame(frame.id) }
        .gesture(
          !isSelected
            ? DragGesture(minimumDistance: 2)
              .onChanged { value in
                if frameMove == nil { frameMove = frame.rect }
                guard let start = frameMove else { return }
                frameViewModel.moveFrame(id: frame.id, start: start, translation: value.translation, container: containerSize)
              }
              .onEnded { _ in frameMove = nil }
            : nil
        )
        .simultaneousGesture(
          !isSelected
            ? MagnifyGesture()
              .onChanged { value in
                if frameScale == nil { frameScale = frame.rect }
                guard let start = frameScale else { return }
                frameViewModel.resizeFrame(id: frame.id, start: start, scale: value.magnification)
              }
              .onEnded { _ in frameScale = nil }
            : nil
        )

      // Corner 핸들 표시
      if isSelected {
        ForEach([Corner.topLeft, .topRight, .bottomLeft, .bottomRight], id: \.self) { corner in
          Circle()
            .fill(.white)
            .frame(width: 14, height: 14)
            .position(cornerPosition(for: corner))
            .gesture(
              DragGesture(minimumDistance: 0)
                .onChanged { value in
                  if cornerScale == nil { cornerScale = frame.rect }
                  guard let start = cornerScale else { return }
                  frameViewModel.resizeCorner(
                    id: frame.id,
                    corner: corner,
                    start: start,
                    translation: value.translation,
                    container: containerSize
                  )
                }
                .onEnded { _ in cornerScale = nil }
            )
        }
      }
    }
  }
  /// 모서리 핸들의 위치에 대한 함수
  private func cornerPosition(for corner: Corner) -> CGPoint {
    let rect = frame.rect
    switch corner {
    case .topLeft:
      return CGPoint(x: rect.minX * containerSize.width, y: rect.minY * containerSize.height)
    case .topRight:
      return CGPoint(x: rect.maxX * containerSize.width, y: rect.minY * containerSize.height)
    case .bottomLeft:
      return CGPoint(x: rect.minX * containerSize.width, y: rect.maxY * containerSize.height)
    case .bottomRight:
      return CGPoint(x: rect.maxX * containerSize.width, y: rect.maxY * containerSize.height)
    }
  }
}
