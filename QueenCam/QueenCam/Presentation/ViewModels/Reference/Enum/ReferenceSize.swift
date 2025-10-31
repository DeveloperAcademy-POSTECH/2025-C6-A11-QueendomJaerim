//
//  ReferenceSize.swift
//  QueenCam
//
//  Created by Bora Yun on 10/31/25.
//

import CoreFoundation

enum ReferenceSize {
  case vertical1
  case vertical2
  case square
  case horizontal1
  case horizontal2
  case none
  
  var width: CGFloat {
    switch self {
    case .vertical1: return 90
    case .vertical2: return 105
    case .square: return 120
    case .horizontal1: return 140
    case .horizontal2 : return 160
    case .none: return 105 //일반적인 4:3 비율에 맞춤
    }
  }
  
  var height: CGFloat {
    switch self {
    case .vertical1: return 160
    case .vertical2: return 140
    case .square: return 120
    case .horizontal1: return 105
    case .horizontal2 : return 90
    case .none: return 140 //일반적인 4:3 비율에 맞춤
    }
  }
  static func referenceRatio(width: CGFloat, height: CGFloat) -> ReferenceSize {
    let ratio: CGFloat = height / width
    if ratio == 16/9 {
      return .vertical1
    } else if ratio == 4/3 {
      return .vertical2
    } else if ratio == 1 {
      return .square
    } else if ratio == 3/4 {
      return .horizontal1
    } else if ratio == 9/16 {
      return .horizontal2
    } else {
      return .none
    }
  }
}
