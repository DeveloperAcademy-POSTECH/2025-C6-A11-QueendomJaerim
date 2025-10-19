//
//  PenViewModel.swift
//  QueenCam
//
//  Created by 윤보라 on 10/15/25.
//

import Combine
import Foundation
import SwiftUI

@Observable
final class PenViewModel {
  var strokes: [Pen] = []  // 현재 그려진 모든 선들(Pen의 배열)
  var redoStrokes: [Pen] = []  // 사용자가 Redo(복귀) 했을때 되돌릴 수 있는 선들

  // MARK: - 선 그리기
  func startStroke(at point: CGPoint) {  // 그리기 시작
    // 새로운 획을 그리면 redo는 초기화
    if !redoStrokes.isEmpty { redoStrokes.removeAll() }
    strokes.append(Pen(points: [point]))
  }
  func appendPoint(_ point: CGPoint) {  // 그리는 중
    if strokes.isEmpty {
      startStroke(at: point)
      return
    }
    strokes[strokes.count - 1].points.append(point)
  }
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
