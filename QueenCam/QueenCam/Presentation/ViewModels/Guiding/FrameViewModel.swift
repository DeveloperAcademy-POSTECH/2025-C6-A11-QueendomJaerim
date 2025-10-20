//
//  FrameViewModel.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//

import Foundation
import SwiftUI
import Combine

@Observable
final class FrameViewModel {
  var frames: [Frame] = []
  var selectedFrameID: UUID? = nil

  //MARK: - 프레임 추가
  let maxFrames = 5  //프레임은 최대 5개까지 혀용
  private let colors: [Color] = [
    .green.opacity(0.5),
    .blue.opacity(0.5),
    .pink.opacity(0.5),
    .orange.opacity(0.5),
    .purple.opacity(0.5),
  ]
  
  // MARK: - 네트워크
  let networkService: NetworkServiceProtocol
  var cancellables: Set<AnyCancellable> = []
  
  init(
    networkService: NetworkServiceProtocol = DependencyContainer.defaultContainer.networkService
  ) {
    self.networkService = networkService

    bind()
  }

  func addFrame(
    at origin: CGPoint,
    size: CGSize = .init(width: 0.3, height: 0.4)
  ) {
    guard frames.count < maxFrames else { return }

    let newX = min(max(origin.x, 0), 1 - size.width)
    let newY = min(max(origin.y, 0), 1 - size.height)

    let rect = CGRect(origin: .init(x: newX, y: newY), size: size)
    let color = colors[frames.count % colors.count]
    let frame = Frame(rect: rect, color: color)
    frames.append(frame)
    
    // Send to network
    sendFrameCommand(command: .add(frame: frame))
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
    
    // Send to network
    sendFrameCommand(command: .move(frame: frames[idx]))
  }

  // MARK: - 프레임의 삭제 및 복구
  func remove(_ id: UUID) {
    frames.removeAll { $0.id == id }
    
    // Send to network
    sendFrameCommand(command: .remove(id: id))
  }
  
  func removeAll() {
    frames.removeAll()
    selectedFrameID = nil
    
    // Send to network
    sendFrameCommand(command: .removeAll)
  }
}

// MARK: Receiving network event
extension FrameViewModel {
  private func bind() {
    networkService.networkEventPublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] event in
        switch event {
        case .frameUpdated(let eventType):
          self?.handleFrameEvent(eventType: eventType)
        default: break
        }
      }
      .store(in: &cancellables)
  }
  
  private func handleFrameEvent(eventType: FrameEventType) {
    switch eventType {
    case .add(let framePayload):
      let frame = FrameMapper.convert(payload: framePayload)
      
      if !frames.contains(where: { $0.id == frame.id }) {
        frames.append(frame)
        print("!!!! Frame 추가됨!!!! \(frame.id)")
      }
    case .replace(let framePayload):
      let replaceTo = FrameMapper.convert(payload: framePayload)
      let targetId = replaceTo.id
      
      frames = frames.map { frame in
        if frame.id == targetId {
          return replaceTo
        }
        
        return frame
      }
    case .delete(let id):
      remove(id)
    case .deleteAll:
      removeAll()
    }
  }
}

// MARK: Sending network event
extension FrameViewModel {
  private func sendFrameCommand(command: FrameNetworkCommand) {
    var sendingEventType: FrameEventType
    
    switch command {
    case .add(let frame):
      sendingEventType = .add(FrameMapper.convert(frame: frame))
    case .move(let frame):
      sendingEventType = .replace(FrameMapper.convert(frame: frame))
    case .remove(let id):
      sendingEventType = .delete(id: id)
    case .removeAll:
      sendingEventType = .deleteAll
    }
    
    Task.detached { [weak self] in
      guard let self else { return }
      await self.networkService.send(for: .frameUpdated(sendingEventType))
    }
  }
}

private enum FrameNetworkCommand {
  case add(frame: Frame)
  case move(frame: Frame)
  case remove(id: UUID)
  case removeAll
}
