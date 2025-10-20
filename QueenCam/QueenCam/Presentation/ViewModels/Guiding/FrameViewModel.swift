//
//  FrameViewModel.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//

import Foundation
import SwiftUI

@Observable
final class FrameViewModel {
  var frames: [Frame] = []
  var selectedFrameID: UUID? = nil

  func allFrames() -> [Frame] { frames }

  //MARK: - 프레임 추가
  let maxFrames = 5  //프레임은 최대 5개까지 혀용
  private let colors: [Color] = [
    .green.opacity(0.5),
    .blue.opacity(0.5),
    .pink.opacity(0.5),
    .orange.opacity(0.5),
    .purple.opacity(0.5),
  ]

  func addFrame(
    at origin: CGPoint,
    size: CGSize = .init(width: 0.3, height: 0.4)
  ) {
    guard frames.count < maxFrames else { return }

    let newX = min(max(origin.x, 0), 1 - size.width)
    let newY = min(max(origin.y, 0), 1 - size.height)

    let rect = CGRect(origin: .init(x: newX, y: newY), size: size)
    let color = colors[frames.count % colors.count]
    frames.append(Frame(rect: rect, color: color))
  }

  //MARK: - 프레임 선택
  func selectFrame(_ id: UUID?) {
    selectedFrameID = id
  }

  func isSelected(_ id: UUID) -> Bool {
    return selectedFrameID == id
  }

  // MARK: - 프레임 이동
  func moveFrame(
    id: UUID,
    start: CGRect,
    translation: CGSize,
    container: CGSize
  ) {

    guard let idx = frames.firstIndex(where: { $0.id == id }) else { return }

    // 상대 단위로 변환
    let dx = container.width > 0 ? translation.width / container.width : 0
    let dy = container.height > 0 ? translation.height / container.height : 0

    var new = start
    new.origin.x += dx
    new.origin.y += dy

    // 경계 안으로 보정
    new.origin.x = min(max(new.origin.x, 0), 1 - new.size.width)
    new.origin.y = min(max(new.origin.y, 0), 1 - new.size.height)

    frames[idx].rect = new
  }

  // MARK: - 프레임의 삭제 및 복구
  func remove(_ id: UUID) {
    frames.removeAll { $0.id == id }
  }
  func removeAll() {
    frames.removeAll()
    selectedFrameID = nil
  }
}
