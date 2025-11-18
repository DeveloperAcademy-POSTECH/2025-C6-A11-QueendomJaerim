//
//  Role+UI.swift
//  QueenCam
//
//  Created by 임영택 on 11/9/25.
//

import Foundation

extension Role {
  var displayName: String {
    switch self {
    case .photographer: return "촬영"
    case .model: return "모델"
    }
  }

  var userDescriptiopn: String {
    switch self {
    case .photographer: return "내 기기로 사진을 촬영해요.\n동시에 친구에게 화면을 실시간으로 공유합니다."
    case .model: return "내가 사진 속 주인공이에요.\n카메라 속 내 모습을 실시간으로 볼 수 있어요."
    }
  }
}
