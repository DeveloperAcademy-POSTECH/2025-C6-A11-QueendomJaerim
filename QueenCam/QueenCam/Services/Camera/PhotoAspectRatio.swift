//
//  PhotoAspectRatio.swift
//  QueenCam
//
//  Created by seungchan on 10/23/26.
//

import Foundation

/// 촬영 비율. rawValue는 설정 저장과 기기 간 전송에 쓰이므로 바꾸지 않는다.
nonisolated enum PhotoAspectRatio: String, CaseIterable, Codable, Sendable {
  case ratio4x3 = "4:3"
  case ratio16x9 = "16:9"
  case ratio1x1 = "1:1"
}

nonisolated extension PhotoAspectRatio {
  /// 상단 비율 버튼을 탭했을 때의 다음 비율 (4:3 → 16:9 → 1:1 → 4:3)
  func next() -> PhotoAspectRatio {
    switch self {
    case .ratio4x3:
      return .ratio16x9
    case .ratio16x9:
      return .ratio1x1
    case .ratio1x1:
      return .ratio4x3
    }
  }

  var longSide: Int {
    switch self {
    case .ratio4x3:
      return 4
    case .ratio16x9:
      return 16
    case .ratio1x1:
      return 1
    }
  }

  var shortSide: Int {
    switch self {
    case .ratio4x3:
      return 3
    case .ratio16x9:
      return 9
    case .ratio1x1:
      return 1
    }
  }
}
