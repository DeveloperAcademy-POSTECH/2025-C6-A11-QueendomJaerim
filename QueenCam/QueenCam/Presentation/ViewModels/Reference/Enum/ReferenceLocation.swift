//
//  ReferenceLocation.swift
//  QueenCam
//
//  Created by Bora Yun on 10/24/25.
//
import Foundation
import SwiftUI

///레퍼런스 위치에 따른 enum
enum ReferenceLocation {
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight

  var alignment: Alignment {
    switch self {
    case .topLeft: return .topLeading
    case .topRight: return .topTrailing
    case .bottomLeft: return .bottomLeading
    case .bottomRight: return .bottomTrailing
    }
  }
  static func corner(point: CGPoint, size: CGSize) -> ReferenceLocation {
    let midX = size.width / 2
    let midY = size.height / 2

    if point.x < midX && point.y < midY {
      return .topLeft
    } else if point.x > midX && point.y < midY {
      return .topRight
    } else if point.x < midX && point.y > midY {
      return .bottomLeft
    } else {
      return .bottomRight
    }
  }
}
