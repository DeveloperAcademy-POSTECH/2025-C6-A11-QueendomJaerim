//
//  FrameViewModel.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//
import Foundation
import SwiftUI
import Combine

/// 프레임의 상태 관리(이동, 확대, 축소, 모서리 크기 조절)
@Observable
final class FrameViewModel {
  static let frameWidth : CGFloat = 0.3
  static let frameHeight : CGFloat = 0.4
  
  var frames: [Frame] = []
  var selectedFrameID: UUID? = nil
  let maxFrames = 1
  private let colors: [Color] = [
    .green.opacity(0.5)
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

  // MARK: - 프레임 추가
  func addFrame(at origin: CGPoint, size: CGSize = .init(width: frameWidth, height: frameHeight)) {
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

  // MARK: - 프레임 선택
  func selectFrame(_ id: UUID?) { selectedFrameID = id }
  func isSelected(_ id: UUID) -> Bool { return selectedFrameID == id }

  // MARK: - 프레임 이동
  func moveFrame(id: UUID, start: CGRect, translation: CGSize, container: CGSize) {
    guard let frameIndex = frames.firstIndex(where: { $0.id == id }) else { return }

    let dx = container.width > 0 ? translation.width / container.width : 0
    let dy = container.height > 0 ? translation.height / container.height : 0

    var new = start
    new.origin.x += dx
    new.origin.y += dy
    new.origin.x = min(max(new.origin.x, 0), 1 - new.size.width)
    new.origin.y = min(max(new.origin.y, 0), 1 - new.size.height)
    frames[frameIndex].rect = new

    // Send to network
    sendFrameCommand(command: .move(frame: frames[frameIndex]))
  }
  // MARK: - 프레임 크기 조절 (Pinch/Magnify)
  func resizeFrame(id: UUID, start: CGRect, scale: CGFloat) {
    guard let frameIndex = frames.firstIndex(where: { $0.id == id }) else { return }

    var new = start
    new.size.width = min(max(start.size.width * scale, 0.05), 1.0)
    new.size.height = min(max(start.size.height * scale, 0.05), 1.0)
    let dx = (start.size.width - new.size.width) / 2
    let dy = (start.size.height - new.size.height) / 2
    new.origin.x += dx
    new.origin.y += dy
    new.origin.x = min(max(new.origin.x, 0), 1 - new.size.width)
    new.origin.y = min(max(new.origin.y, 0), 1 - new.size.height)
    frames[frameIndex].rect = new
    
    // Send to network
    sendFrameCommand(command: .modify(frame: frames[frameIndex]))
  }
  // MARK: - 모서리 핸들로 비율 조절
  func resizeCorner(id: UUID, corner: Corner, start: CGRect, translation: CGSize, container: CGSize) {
    guard let frameIndex = frames.firstIndex(where: { $0.id == id }) else { return }

    var new = start
    let dx = translation.width / container.width
    let dy = translation.height / container.height

    switch corner {
    case .topLeft:
      new.origin.x += dx
      new.origin.y += dy
      new.size.width -= dx
      new.size.height -= dy

    case .topRight:
      new.origin.y += dy
      new.size.width += dx
      new.size.height -= dy

    case .bottomLeft:
      new.origin.x += dx
      new.size.width -= dx
      new.size.height += dy

    case .bottomRight:
      new.size.width += dx
      new.size.height += dy
    }
    new.size.width = min(max(new.size.width, 0.05), 1.0)
    new.size.height = min(max(new.height, 0.05), 1.0)
    new.origin.x = min(max(new.minX, 0), 1 - new.width)
    new.origin.y = min(max(new.minY, 0), 1 - new.height)
    frames[frameIndex].rect = new
    
    // Send to network
    sendFrameCommand(command: .modify(frame: frames[frameIndex]))
  }
  // MARK: - 프레임의 삭제
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
      frames.removeAll { $0.id == id }  // remove나 removeAll 함수를 재사용하지 말 것. 네트워크로 전파하며 무한 루프 시작됨.
    case .deleteAll:
      frames.removeAll()
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
    case .modify(let frame):
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
  case modify(frame: Frame)
  case remove(id: UUID)
  case removeAll
}
