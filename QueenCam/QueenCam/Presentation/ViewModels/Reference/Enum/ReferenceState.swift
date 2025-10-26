//
//  ReferenceState.swift
//  QueenCam
//
//  Created by Bora Yun on 10/24/25.
//
import Foundation

/// 레퍼런스 상태를 표현하는 이넘
enum ReferenceState: Equatable {
  case open  // Reference(PiP) 모드 활성화
  case close  // Reference(PiP) 모두 비활성화
  case delete  // Reference(PiP) 삭제
}
