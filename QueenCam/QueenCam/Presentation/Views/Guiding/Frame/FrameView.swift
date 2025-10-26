//
//  FrameLayerView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//  개별 프레임 뷰

import SwiftUI

struct FrameView: View {
  let frame: Frame
  let containerSize: CGSize
  // 외부 콜백
  let onDrag: (_ startRect: CGRect, _ translation: CGSize) -> Void
  let onResize: (_ newRect: CGRect) -> Void
  let onTap: () -> Void
  let onDelete: () -> Void
  
  var isSelected: Bool
  
  @State private var startRectMove: CGRect? = nil
  

  var body: some View {
    let rect = frame.rect

    //픽셀(절대) 단위로 변환
    let newWidth = rect.width * containerSize.width
    let newHeight = rect.height * containerSize.height
    let newX = (rect.minX + rect.width / 2) * containerSize.width
    let newY = (rect.minY + rect.height / 2) * containerSize.height

    //프레임 사격형 표시
    ZStack(alignment: .topTrailing) {

      Rectangle()
        .fill(frame.color)
        .overlay(
          Rectangle().stroke(isSelected ? .black : frame.color, lineWidth: 2)
        )
        .frame(width: newWidth, height: newHeight)
        .gesture(
          isSelected
            ? DragGesture(minimumDistance: 0)
              .onChanged { value in
                if startRectMove == nil { startRectMove = frame.rect }
                guard let start = startRectMove else {return}
                onDrag(start, value.translation)
              }
              .onEnded { _ in
                startRectMove = nil
              }
            : nil
        )
        .onTapGesture {
          onTap()
        }
        .animation(.snappy, value: frame.rect)

      if isSelected {
        Button {
          onDelete()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.blue)
        }
      }
    }.position(x: newX, y: newY)
      .animation(.snappy, value: frame.rect)
  }
}
