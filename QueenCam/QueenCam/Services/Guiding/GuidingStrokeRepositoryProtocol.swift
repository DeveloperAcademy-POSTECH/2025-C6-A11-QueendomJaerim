//
//  GuidingStrokeRepositoryProtocol.swift
//  QueenCam
//
//  Created by 임영택 on 6/21/26.
//

import CoreGraphics
import Foundation

struct StrokeSnapshot: Equatable {
  let persistedStrokes: [Stroke]
  let strokes: [Stroke]
  let deleteStrokes: [[Stroke]]
}

struct DrawableStroke: Equatable {
  let id: UUID
  let points: [CGPoint]
  let author: Role
}

protocol GuidingStrokeRepositoryProtocol: AnyObject {
  var snapshots: AsyncStream<StrokeSnapshot> { get }

  func currentSnapshot() -> StrokeSnapshot
  func captureDrawableStrokes() -> [DrawableStroke]

  @discardableResult
  func add(initialPoints: [CGPoint], isMagicPen: Bool, author: Role) -> UUID
  func updateStroke(id: UUID, points: [CGPoint], endDrawing: Bool, author: Role)
  func saveStroke(for author: Role)
  func remove(_ id: UUID, author: Role)
  func deleteAll(for author: Role)
  func reset()
  func undo(for author: Role)
}
