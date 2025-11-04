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
  /// 타 비율의 이미지
  case none
  
  var width: CGFloat {
    switch self {
    case .ratio16x9: return 90
    case .ratio4x3: return 105
    case .ratio1x1: return 120
    case .ratio3x4: return 140
    case .ratio9x16: return 160
    case .none: return 105 //일반적인 4:3 비율에 맞춤
    }
  }
  
  var height: CGFloat {
    switch self {
    case .ratio16x9: return 160
    case .ratio4x3: return 140
    case .ratio1x1: return 120
    case .ratio3x4: return 105
    case .ratio9x16 : return 90
    case .none: return 140 //일반적인 4:3 비율에 맞춤
    }
  }
  static func referenceRatio(width: CGFloat, height: CGFloat) -> ReferenceSize {
    let ratio: CGFloat = height / width
    if ratio == 16/9 {
      return .ratio16x9
    } else if ratio == 4/3 {
      return .ratio4x3
    } else if ratio == 1 {
      return .ratio1x1
    } else if ratio == 3/4 {
      return .ratio3x4
    } else if ratio == 9/16 {
      return .ratio9x16
    } else {
      return .none
    }
  }
}
