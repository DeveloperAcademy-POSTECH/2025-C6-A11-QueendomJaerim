//
//  Frame.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.

import Foundation
import SwiftUI

/// 하나의 프레임 모델
struct Frame: Identifiable, Equatable {
  let id: UUID
  var rect: CGRect  // 사각형의 위치(x,y)와 크기(width, height)

  init(id: UUID = UUID(), rect: CGRect) {
    self.id = id
    self.rect = rect
  }
}
