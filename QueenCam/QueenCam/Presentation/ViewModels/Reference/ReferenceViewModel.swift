//
//  ReferenceViewModel.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//  Reference의 Open/Close 제스쳐 관리 ViewModel

import Combine
import Foundation
import SwiftUI
import UIKit

@Observable
final class ReferenceViewModel {
  var image: UIImage?  // 선택된 레퍼런스 사진
  var selectedImageID: String?

  var state: ReferenceState = .open
  var dragOffset: CGSize = .zero  // 드래그 중 임시편차

  // MARK: - 드래그 Close(Fold) 제스쳐
  let foldThreshold: CGFloat = -30  // fold(접힘) 전환 임계값 - 변경 예정
  let maxDrag: CGFloat = 60  // 최대 드래그 허용 범위(양수: 오른쪽, 음수: 왼쪽)
  // 드래그 중: 수평만 처리
  func dragChanged(_ value: DragGesture.Value) {
    let x = value.translation.width
    dragOffset = .init(width: min(x, maxDrag), height: 0)
  }
  // 드래그 끝: 임계값(foldThreshold) 넘기면 접힘
  func dragEnded() {
    if dragOffset.width <= foldThreshold {
      state = .close
    }
    withAnimation(.snappy) {
      dragOffset = .zero
    }
  }
  // MARK: - 드래그 Open(Unfold) 제스쳐
  func unFold() {
    withAnimation(.snappy) {
      state = .open
      dragOffset = .zero
    }
  }
  // MARK: - Reference 삭제
  func onDelete() {  //초기화
    withAnimation(.snappy) {
      state = .delete
      image = nil
      selectedImageID = nil
    }
  }
}
