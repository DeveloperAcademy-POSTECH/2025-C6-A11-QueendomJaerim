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
  /// 이전 세션에 그려진 모든 선(stroke)들 - Undo 불가
  var persistedStrokes: [Stroke] = []
  /// 현재 세션 중 그려진 모든 선(stroke)들
  var strokes: [Stroke] = []
  /// 사용자가 전체삭제 했던 선(stroke)들
  var deleteStrokes: [[Stroke]] = []
  /// 현재 사용자의 역할(모델, 작가, 미연결)
  var currentRole: Role?
  /// 미연결(nil)인 경우 작가로 역할 부여
  private var myRole: Role { currentRole ?? .photographer }
  /// 세션 동안 내가 한 번이라도 그렸는지 여부
  var hasEverDrawn: Bool = false

  // 가이드 최초 1회
  private var hasShownPenToast = false
  private var hasShownMagicPenToast: Bool = false

  // MARK: - 네트워크
  let networkService: NetworkServiceProtocol
  var cancellables: Set<AnyCancellable> = []

  // MARK: - Toast
  let notificationService: NotificationServiceProtocol

  init(
    networkService: NetworkServiceProtocol = DependencyContainer.defaultContainer.networkService,
    notificationService: NotificationServiceProtocol = DependencyContainer.defaultContainer.notificationService
  ) {
    self.networkService = networkService
    self.notificationService = notificationService

    bind()
  }

  // MARK: - 드로잉 시작/진행 업데이트
  func add(initialPoints: [CGPoint], isMagicPen: Bool, author: Role) -> UUID {
    let stroke = Stroke(points: initialPoints, isMagicPen: isMagicPen, author: author, endDrawing: false)
    strokes.append(stroke)

    if author == myRole && hasEverDrawn == false {
      hasEverDrawn = true
    }

    // Send to network
    sendPenCommand(command: .add(stroke: stroke))
    return stroke.id
  }

  /// 진행 중 스트로크의 포인트를 갱신 +  .replace 이벤트를 전송
  func updateStroke(id: UUID, points: [CGPoint], endDrawing: Bool) {
    guard let strokeIndex = strokes.firstIndex(where: { $0.id == id }) else { return }
    if strokes[strokeIndex].author != myRole { return }
    strokes[strokeIndex].points = points
    strokes[strokeIndex].endDrawing = endDrawing
    // Send to network
    sendPenCommand(command: .replace(stroke: strokes[strokeIndex]))
  }
  // MARK: 세션 종료 후 Stroke 저장
  /// 펜 툴 해제(세션 종료) 시 본인 stroke를 strokes에서 persistedStrokes로 이관
  func saveStroke() {
    // strokes에 있는 본인 stroke 찾기
    let myStrokes = strokes.filter { $0.author == myRole }
    if !myStrokes.isEmpty {
      // 해당 stroke를 persistedStrokes로 appmend
      persistedStrokes.append(contentsOf: myStrokes)
      // 해당 stroke를 strokes에서 삭제(remove)
      strokes.removeAll { $0.author == myRole }
    }
  }

  // MARK: - 스트로크 삭제
  /// 펜 가이딩 개별 획(stroke)  삭제 - 매직펜
  func remove(_ id: UUID) {
    guard
      let target = strokes.first(where: { $0.id == id }),
      target.author == myRole
    else { return }

    strokes.removeAll { $0.id == id }

    // Send to network
    sendPenCommand(command: .remove(id: id))
  }

  /// 본인이 생성한 펜 가이딩 전체 삭제
  func deleteAll() {
    // 내가 생성한 stroke 배열과 id 배열
    let myStrokes = strokes.filter { $0.author == myRole }
    let myPersistedStrokes = persistedStrokes.filter {$0.author == myRole}
    let allMyStrokes = myStrokes + myPersistedStrokes
    if !allMyStrokes.isEmpty {
      deleteStrokes.append(myStrokes) // 전체 삭제 이후, Undo는 현재 세션에 작업한 strokes만 포함
    }

    let myIds = allMyStrokes.map(\.id)

    strokes.removeAll { $0.author == myRole }
    persistedStrokes.removeAll { $0.author == myRole }

    //   Send to network
    for id in myIds {
      sendPenCommand(command: .remove(id: id))
    }
  }

  /// 펜 가이딩 초기화
  func reset() {
    strokes.removeAll()
    hasEverDrawn = false

    // Send to network
    sendPenCommand(command: .reset)
  }

  // MARK: - 스트로크 실행취소/재실행
  func undo() {
    if strokes.isEmpty, let recentDeleteStrokes = deleteStrokes.popLast() {
      strokes.append(contentsOf: recentDeleteStrokes)
      for stroke in recentDeleteStrokes {
        sendPenCommand(command: .add(stroke: stroke))
      }
      return
    }
    guard let index = strokes.lastIndex(where: { $0.author == myRole }) else { return }

    let last = strokes.remove(at: index)

    // Send to network
    sendPenCommand(command: .remove(id: last.id))
  }

  // MARK: - 토스트
  enum GuidingType {
    case pen
    case magicPen
  }

  // 처음으로 펜+ 매직펜 툴 선택 할때 토스트
  func showFirstToolToast(type: GuidingType) {
    switch type {
    case .pen:
      guard !hasShownPenToast else { return }
      notificationService.registerNotification(DomainNotification.make(type: .firstPenToolSelected))
    case .magicPen:
      guard !hasShownMagicPenToast else { return }
      notificationService.registerNotification(DomainNotification.make(type: .firstMagicToolSelected))
    }
  }
  // 지우개로 펜 가이드라인 지울때마다의 토스트
  func showEraseGuidingLineToast() {
    notificationService.registerNotification(DomainNotification.make(type: .penEraserSelected))
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
      persistedStrokes.removeAll { $0.id == id }
    case .reset:
      strokes.removeAll()
      hasEverDrawn = false
    }
  }
}

// MARK: Sending network event
private enum PenNetworkCommand {
  case add(stroke: Stroke)
  case replace(stroke: Stroke)
  case remove(id: UUID)
  case reset
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
    case .reset:
      sendingEventType = .reset
    }
    Task.detached { [weak self] in
      guard let self else { return }
      await self.networkService.send(for: .penUpdated(sendingEventType))
    }
  }
}
