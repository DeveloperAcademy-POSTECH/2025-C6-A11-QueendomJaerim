//
//  Frame.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//  하나의 사각형 프레임 모델

import Foundation
import SwiftUI

struct Frame: Identifiable, Equatable {
  let id: UUID
  var rect: CGRect  // 사각형의 위치(x,y)와 크기(width, height)
  let color: Color

  init(id: UUID = UUID(), rect: CGRect, color: Color) {
    self.id = id
    self.rect = rect
    self.color = color
  }
}
