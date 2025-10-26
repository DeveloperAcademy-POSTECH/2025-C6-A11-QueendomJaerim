//
//  PenViewModel.swift
//  QueenCam
//
//  Created by 윤보라 on 10/15/25.
//
import Foundation
import SwiftUI

@Observable
final class PenViewModel {
  var strokes: [Stroke] = []  // 현재 그려진 모든 선들(Pen의 배열)
  var disappearStokes: [Stroke] = []
  var redoStrokes: [Stroke] = []  // 사용자가 Redo(복귀) 했을때 되돌릴 수 있는 선들
  // MARK: - 선 삭제
  func clearAll() {  // 전체 삭제
    strokes.removeAll()
    redoStrokes.removeAll()
  }
  // MARK: - 선 실행취소/재실행
  func undo() {
    guard let last = strokes.popLast() else { return }
    redoStrokes.append(last)
  }
  func redo() {
    guard let redoStroke = redoStrokes.popLast() else { return }
    strokes.append(redoStroke)
  }
}
