//
//  ReferenceSize.swift
//  QueenCam
//
//  Created by Bora Yun on 10/31/25.
//

import Foundation

enum ReferenceSize {
  /// 16:9 비율의 이미지
  case ratio16x9
  /// 4:3 비율의 이미지
  case ratio4x3
  /// 1:1 비율의 이미지
  case ratio1x1
  /// 3:4 비율의 이미지
  case ratio3x4
  /// 9:16 비율의 이미지
  case ratio9x16

  /// 원본 이미지의 비율에 따른 레퍼런스의 가로 너비
  var width: CGFloat {
    switch self {
    case .ratio16x9: return 90
    case .ratio4x3: return 105
    case .ratio1x1: return 120
    case .ratio3x4: return 140
    case .ratio9x16: return 160
    }
  }

  static func referenceRatio(width: CGFloat, height: CGFloat) -> ReferenceSize {
    let ratio: CGFloat = height / width
    if ratio >= 16 / 9 {
      return .ratio16x9
    } else if 16 / 9 > ratio && ratio >= 4 / 3 {
      return .ratio4x3
    } else if 4 / 3 > ratio && ratio > 1 {
      return .ratio1x1
    } else if 1 >= ratio && ratio > 3 / 4 {
      return .ratio1x1
    } else if 3 / 4 >= ratio && ratio > 9 / 16 {
      return .ratio3x4
    } else {
      return .ratio9x16
    }
  }
}
