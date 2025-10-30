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
  var strokes: [Stroke] = []  // 현재 그려진 모든 선들(Pen의 배열)
  var redoStrokes: [Stroke] = []  // 사용자가 Redo(복귀) 했을때 되돌릴 수 있는 선들
  /// 현재 사용자의 역할(모델, 작가)
  var currentRole: Role?

  // MARK: - 네트워크
  let networkService: NetworkServiceProtocol
  var cancellables: Set<AnyCancellable> = []

  init(
    networkService: NetworkServiceProtocol = DependencyContainer.defaultContainer.networkService
  ) {
    self.networkService = networkService

    bind()
  }

  // MARK: - 드로잉 시작/진행 업데이트
  func add(initialPoints: [CGPoint], author: Role) -> UUID {
    let stroke = Stroke(points: initialPoints, author: author)
    strokes.append(stroke)
    redoStrokes.removeAll()

    // Send to network
    sendPenCommand(command: .add(stroke: stroke))
    return stroke.id
  }

  /// 진행 중 스트로크의 포인트를 갱신하고 .replace 이벤트를 전송한다.
  func updateStroke(id: UUID, points: [CGPoint]) {
    guard let strokeIndex = strokes.firstIndex(where: { $0.id == id }) else { return }
    if let myRole = currentRole, strokes[strokeIndex].author != myRole { return }
    strokes[strokeIndex].points = points

    // Send to network
    sendPenCommand(command: .replace(stroke: strokes[strokeIndex]))
  }

  // MARK: - 스트로크 삭제
  func remove(_ id: UUID) { // 개별 스트로크 삭제(매직펜)
    guard let myRole = currentRole,
          let target = strokes.first(where: { $0.id == id }),
          target.author == myRole else { return }

    strokes.removeAll { $0.id == id }
    redoStrokes.removeAll { $0.id == id }

    // Send to network
    sendPenCommand(command: .remove(id: id))
  }

  func removeAll() {  // 전체 삭제
    guard let myRole = currentRole else { return }

    let myIds = strokes.filter { $0.author == myRole }.map(\.id)
    strokes.removeAll { $0.author == myRole }
    redoStrokes.removeAll { $0.author == myRole }

  
    for id in myIds {
      sendPenCommand(command: .remove(id: id))
    }
  }

  // MARK: - 스트로크 실행취소/재실행
  func undo() {
    guard let myRole = currentRole else { return }
    guard let index = strokes.lastIndex(where: { $0.author == myRole }) else { return }

    let last = strokes.remove(at: index)
    redoStrokes.append(last)

    // Send to network
    sendPenCommand(command: .remove(id: last.id))
  }

  func redo() {
    guard let myRole = currentRole else { return }
    guard let index = redoStrokes.lastIndex(where: { $0.author == myRole }) else { return }

    let redoStroke = redoStrokes.remove(at: index)
    strokes.append(redoStroke)

    // Send to network
    sendPenCommand(command: .add(stroke: redoStroke))
  }
}

// MARK: Receiving network event
extension PenViewModel {
  private func bind() {
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
  private func handlePenEvent(eventType: PenEventType) {
    switch eventType {
    case .add(let penPayload):
      let stroke = PenMapper.convert(payload: penPayload)

      if !strokes.contains(where: { $0.id == stroke.id }) {
        strokes.append(stroke)
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
    case .delete(let id):
      strokes.removeAll { $0.id == id }
      redoStrokes.removeAll { $0.id == id }
    }
  }
}

// MARK: Sending network event
private enum PenNetworkCommand {
  case add(stroke: Stroke)
  case replace(stroke: Stroke)
  case remove(id: UUID)
}

extension PenViewModel {
  private func sendPenCommand(command: PenNetworkCommand) {
    var sendingEventType: PenEventType

    switch command {
    case .add(let stroke):
      sendingEventType = .add(PenMapper.convert(stroke: stroke))
    case .replace(let stroke):
      sendingEventType = .replace(PenMapper.convert(stroke: stroke))
    case .remove(let id):
      sendingEventType = .delete(id: id)
    }
    Task.detached { [weak self] in
      guard let self else { return }
      await self.networkService.send(for: .penUpdated(sendingEventType))
    }
  }
}
