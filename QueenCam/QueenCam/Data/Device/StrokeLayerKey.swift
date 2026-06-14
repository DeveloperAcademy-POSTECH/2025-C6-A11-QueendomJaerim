//
//  StrokeLayerKey.swift
//  QueenCam
//
//  Created by 임영택 on 6/14/26.
//

import Foundation

struct StrokeLayerKey: Hashable {
  let rawValue: String

  init(_ rawValue: String) {
    self.rawValue = rawValue
  }
}

