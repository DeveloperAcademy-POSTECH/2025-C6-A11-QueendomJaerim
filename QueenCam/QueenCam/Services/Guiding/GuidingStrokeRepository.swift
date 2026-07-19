//
//  GuidingStrokeRepository.swift
//  QueenCam
//
//  Created by 임영택 on 6/21/26.
//

import Combine
import CoreGraphics
import Foundation

final class GuidingStrokeRepository: GuidingStrokeRepositoryProtocol {
  private var persistedStrokes: [Stroke] = []
  private var strokes: [Stroke] = []
  private var deleteStrokes: [[Stroke]] = []

  private let networkService: NetworkServiceProtocol
  private var cancellables: Set<AnyCancellable> = []

  private let snapshotStream: AsyncStream<StrokeSnapshot>
  private let snapshotContinuation: AsyncStream<StrokeSnapshot>.Continuation

  var snapshots: AsyncStream<StrokeSnapshot> {
    snapshotStream
  }

  init(networkService: NetworkServiceProtocol) {
    self.networkService = networkService
    let stream = AsyncStream.makeStream(of: StrokeSnapshot.self)
    self.snapshotStream = stream.stream
    self.snapshotContinuation = stream.continuation

    bind()
    publishSnapshot()
  }

  deinit {
    snapshotContinuation.finish()
  }

  func currentSnapshot() -> StrokeSnapshot {
    makeSnapshot()
  }

  func captureDrawableStrokes() -> [DrawableStroke] {
    let snapshot = makeSnapshot()
    return (snapshot.persistedStrokes + snapshot.strokes)
      .filter { $0.points.count > 1 && !$0.isMagicPen }
      .map {
        DrawableStroke(
          id: $0.id,
          points: $0.points,
          author: $0.author
        )
      }
  }

  @discardableResult
  func add(initialPoints: [CGPoint], isMagicPen: Bool, author: Role) -> UUID {
    let stroke = Stroke(points: initialPoints, isMagicPen: isMagicPen, author: author, endDrawing: false)
    strokes.append(stroke)
    publishSnapshot()
    sendPenCommand(command: .add(stroke: stroke))
    return stroke.id
  }

  func updateStroke(id: UUID, points: [CGPoint], endDrawing: Bool, author: Role) {
    guard let strokeIndex = strokes.firstIndex(where: { $0.id == id }) else { return }
    guard strokes[strokeIndex].author == author else { return }

    strokes[strokeIndex].points = points
    strokes[strokeIndex].endDrawing = endDrawing
    publishSnapshot()
    sendPenCommand(command: .replace(stroke: strokes[strokeIndex]))
  }

  func saveStroke(for author: Role) {
    let myStrokes = strokes.filter { $0.author == author }
    if !myStrokes.isEmpty {
      persistedStrokes.append(contentsOf: myStrokes)
      strokes.removeAll { $0.author == author }
    }

    let myDeleteStrokes = deleteStrokes.flatMap { $0 }.filter { $0.author == author }
    if !myDeleteStrokes.isEmpty {
      for i in deleteStrokes.indices {
        deleteStrokes[i].removeAll { $0.author == author }
      }
    }

    publishSnapshot()
  }

  func remove(_ id: UUID, author: Role) {
    guard
      let target = strokes.first(where: { $0.id == id }),
      target.author == author
    else { return }

    strokes.removeAll { $0.id == id }
    publishSnapshot()
    sendPenCommand(command: .remove(id: id))
  }

  func deleteAll(for author: Role) {
    let myStrokes = strokes.filter { $0.author == author }
    let myPersistedStrokes = persistedStrokes.filter { $0.author == author }
    let allMyStrokes = myStrokes + myPersistedStrokes

    if !allMyStrokes.isEmpty {
      deleteStrokes.append(myStrokes)
    }

    let myIds = allMyStrokes.map(\.id)

    strokes.removeAll { $0.author == author }
    persistedStrokes.removeAll { $0.author == author }
    publishSnapshot()

    for id in myIds {
      sendPenCommand(command: .remove(id: id))
    }
  }

  func reset() {
    strokes.removeAll()
    persistedStrokes.removeAll()
    deleteStrokes.removeAll()
    publishSnapshot()
    sendPenCommand(command: .reset)
  }

  func undo(for author: Role) {
    if strokes.isEmpty, let recentDeleteStrokes = deleteStrokes.popLast() {
      strokes.append(contentsOf: recentDeleteStrokes)
      publishSnapshot()
      for stroke in recentDeleteStrokes {
        sendPenCommand(command: .add(stroke: stroke))
      }
      return
    }

    guard let index = strokes.lastIndex(where: { $0.author == author }) else { return }
    let last = strokes.remove(at: index)
    publishSnapshot()
    sendPenCommand(command: .remove(id: last.id))
  }
}

// MARK: - Network Events

private enum PenNetworkCommand {
  case add(stroke: Stroke)
  case replace(stroke: Stroke)
  case remove(id: UUID)
  case reset
}

private extension GuidingStrokeRepository {
  func bind() {
    networkService.networkEventPublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] event in
        switch event {
        case .penUpdated(let eventType):
          self?.handlePenEvent(eventType: eventType)
        default: break
        }
      }
      .store(in: &cancellables)
  }

  func handlePenEvent(eventType: PenEventType) {
    switch eventType {
    case .add(let penPayload):
      let stroke = PenMapper.convert(payload: penPayload)

      if !strokes.contains(where: { $0.id == stroke.id }) {
        strokes.append(stroke)
        publishSnapshot()
      }
    case .replace(let penPayload):
      let replaceTo = PenMapper.convert(payload: penPayload)
      let targetId = replaceTo.id

      strokes = strokes.map { stroke in
        if stroke.id == targetId {
          return replaceTo
        }
        return stroke
      }
      publishSnapshot()
    case .delete(let id):
      strokes.removeAll { $0.id == id }
      persistedStrokes.removeAll { $0.id == id }
      publishSnapshot()
    case .reset:
      strokes.removeAll()
      persistedStrokes.removeAll()
      deleteStrokes.removeAll()
      publishSnapshot()
    }
  }

  func sendPenCommand(command: PenNetworkCommand) {
    let sendingEventType: PenEventType

    switch command {
    case .add(let stroke):
      sendingEventType = .add(PenMapper.convert(stroke: stroke))
    case .replace(let stroke):
      sendingEventType = .replace(PenMapper.convert(stroke: stroke))
    case .remove(let id):
      sendingEventType = .delete(id: id)
    case .reset:
      sendingEventType = .reset
    }

    Task.detached { [networkService] in
      await networkService.send(for: .penUpdated(sendingEventType))
    }
  }
}

// MARK: - Snapshot

private extension GuidingStrokeRepository {
  func makeSnapshot() -> StrokeSnapshot {
    StrokeSnapshot(
      persistedStrokes: persistedStrokes,
      strokes: strokes,
      deleteStrokes: deleteStrokes
    )
  }

  func publishSnapshot() {
    snapshotContinuation.yield(makeSnapshot())
  }
}
