//
//  FrameLayerView.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//  개별 프레임 뷰

import SwiftUI

struct FrameLayerView: View {
  let frame: Frame
  let containerSize: CGSize
  let onDrag: (_ startRect: CGRect, _ translation: CGSize) -> Void
  @State private var startRect: CGRect? = nil
  
  var body: some View {
    let rect = frame.rect
    
    //픽셀(절대) 단위로 변환
    let w = rect.width  * containerSize.width
    let h = rect.height * containerSize.height
    let cx = (rect.minX + rect.width  / 2) * containerSize.width
    let cy = (rect.minY + rect.height / 2) * containerSize.height
    
    //프레임 사격형 표시
    Rectangle()
      .fill(frame.color)
      .overlay(
        Rectangle().stroke(frame.color, lineWidth: 2)
      )
      .frame(width: w, height: h)
      .position(x: cx, y: cy)
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if startRect == nil { startRect = frame.rect }
            onDrag(startRect!, value.translation)
          }
          .onEnded { _ in
            startRect = nil
          }
      )
      .animation(.snappy, value: frame.rect)
  }
  
}

