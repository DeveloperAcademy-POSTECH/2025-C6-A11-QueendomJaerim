import Combine
//
//  FrameViewModel.swift
//  QueenCam
//
//  Created by Bora Yun on 10/16/25.
//
import Foundation
import SwiftUI

/// 프레임의 상태 관리(이동, 확대, 축소, 모서리 크기 조절)
@Observable
final class FrameViewModel {
  static let frameWidth: CGFloat = 0.55
  static let frameHeight: CGFloat = 0.69

  var frames: [Frame] = []
  var currentRole: Role?

  /// 프레임 토글 여부
  var isFrameEnabled: Bool = false
  /// 프레임의 현재 소유자
  var frameOwnerRole: Role?
  /// 프레임 현재 수정 중 여부
  var isInteracting: Bool = false
  /// 프레임을 현재 수정 중인 역할(작가, 모델)
  var interactingRole: Role?
  /// 수정 및 선택한 프레임의 식별자
  var selectedFrameID: UUID?
  /// 최대 허용 프레임 갯수
  let maxFrames = 1
  /// 프레임 최소 크기 (절대 좌표 기준)
  let minimumFrameSizeByAbsoulteScale: CGFloat = 67
  /// 프레임 최소 너비
  var minimumFrameWidth: CGFloat {
    minimumFrameSizeByAbsoulteScale / (containerSize?.width ?? 363)
  }
  /// 프레임 최소 높이
  var minimumFrameHeight: CGFloat {
    minimumFrameSizeByAbsoulteScale / (containerSize?.height ?? 484)
  }
  /// 컨테이너 크기
  var containerSize: CGSize?

  // MARK: - 네트워크
  let networkService: NetworkServiceProtocol
  var cancellables: Set<AnyCancellable> = []

  // MARK: - Toast
  let notificationService: NotificationServiceProtocol
  private var hasShownPeerCreateToast: Bool = false
  private var hasShownPeerEditToast: Bool = false
  private var hasShownPeerRatioEditToast: Bool = false
  private var hasShownPeerDeleteToast: Bool = false

  init(
    networkService: NetworkServiceProtocol = DependencyContainer.defaultContainer.networkService,
    notificationService: NotificationServiceProtocol = DependencyContainer.defaultContainer.notificationService
  ) {
    self.networkService = networkService
    self.notificationService = notificationService

    bind()
  }

  func setContainerSize(for size: CGSize) {
    if self.containerSize == nil {
      self.containerSize = size
    }
  }

  // MARK: - 프레임 활성화 토글 + 네트워크
  func setFrame(_ enabled: Bool, _ currentRole: Role?) {
    // 로컬 상태 갱신
    isFrameEnabled = enabled
    frameOwnerRole = currentRole

    // Send to network
    sendFrameEnabled(enabled, currentRole)
  }

  // MARK: - 프레임 추가
  func addFrame(at origin: CGPoint, size: CGSize = .init(width: frameWidth, height: frameHeight)) {
    guard frames.count < maxFrames else { return }
    let newX = min(max(origin.x, 0), 1 - size.width)
    let newY = min(max(origin.y, 0), 1 - size.height)
    let rect = CGRect(origin: .init(x: newX, y: newY), size: size)
    let frame = Frame(rect: rect)
    frames.append(frame)
    selectedFrameID = frame.id

    // Send to network
    sendFrameCommand(command: .add(frame: frame))
  }

  // MARK: - 프레임 선택
  func selectFrame(_ id: UUID?) { selectedFrameID = id }
  func isSelected(_ id: UUID) -> Bool { selectedFrameID == id }

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
    new.size.width = min(max(start.size.width * scale, minimumFrameWidth), 1.0)
    new.size.height = min(max(start.size.height * scale, minimumFrameHeight), 1.0)
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

    var minX = new.minX
    var minY = new.minY
    var maxX = new.maxX
    var maxY = new.maxY

    switch corner {
    case .topLeft:
      minX = start.minX + dx
      minY = start.minY + dy

      minX = min(minX, maxX - minimumFrameWidth)
      minY = min(minY, maxY - minimumFrameHeight)

      minX = max(minX, 0)
      minY = max(minY, 0)
    case .topRight:
      maxX = start.maxX + dx
      minY = start.minY + dy

      maxX = max(maxX, minX + minimumFrameWidth)
      minY = min(minY, maxY - minimumFrameHeight)

      maxX = min(maxX, 1)
      minY = max(minY, 0)
    case .bottomLeft:
      minX = start.minX + dx
      maxY = start.maxY + dy

      minX = min(minX, maxX - minimumFrameWidth)
      maxY = max(maxY, minY + minimumFrameHeight)

      minX = max(minX, 0)
      maxY = min(maxY, 1)
    case .bottomRight:
      maxX = start.maxX + dx
      maxY = start.maxY + dy

      maxX = max(maxX, minX + minimumFrameWidth)
      maxY = max(maxY, minY + minimumFrameHeight)

      maxX = min(maxX, 1)
      maxY = min(maxY, 1)
    }

    new = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

    frames[frameIndex].rect = new

    // Send to network
    sendFrameCommand(command: .modify(frame: frames[frameIndex]))
  }

  // MARK: - 프레임의 삭제
  func deleteAll() {
    frames.removeAll()
    selectedFrameID = nil

    // Send to network
    sendFrameCommand(command: .deleteAll)
  }

  // MARK: - Toast
  func showGuidingDisabledToast() {
    notificationService.registerNotification(DomainNotification.make(type: .turnOnGuidingFirstWithFrame))
  }
  enum FrameToastEventType {
    case create
    case delete
    case edit
    case ratioEdit
  }
  // 상대가 이벤트를 한 경우
  func peerFrameGuidingToast(type: FrameToastEventType) {
    switch type {
    case .create:
      notificationService.registerNotification(DomainNotification.make(type: .peerCreateFrameGuide))
    case .delete:
      notificationService.registerNotification(DomainNotification.make(type: .peerCloseFrameGuide))
    case .edit:
      notificationService.registerNotification(DomainNotification.make(type: .peerEditingFrameGuide))
    case .ratioEdit:
      notificationService.registerNotification(DomainNotification.make(type: .peerFirstEditMode))
    }
  }
  // 사용자(본인)가 이벤트를 한 경우
  func myFrameGuidingToast(type: FrameToastEventType) {
    switch type {
    case .create:
      notificationService.registerNotification(DomainNotification.make(type: .sharingFrameGuideStarted))
    case .delete:
      notificationService.registerNotification(DomainNotification.make(type: .closeFrameGuide))
    case .edit:
      return
    case .ratioEdit:
      notificationService.registerNotification(DomainNotification.make(type: .firstEditMode))
    }
  }
}

// MARK: Receiving network event
extension FrameViewModel {
  private func bind() {
    networkService.networkEventPublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] event in
        guard let self else { return }
        switch event {
        case .frameUpdated(let eventType):
          self.handleFrameEvent(eventType: eventType)

        case .frameEnabled(let enabled, let currentRole):
          self.isFrameEnabled = enabled
          self.frameOwnerRole = currentRole

          // 토스트
          if !hasShownPeerCreateToast {
            peerFrameGuidingToast(type: .create)
            hasShownPeerCreateToast = true
          }
          if !hasShownPeerDeleteToast {
            peerFrameGuidingToast(type: .delete)
            hasShownPeerDeleteToast = true
          }

        case .frameInteracting(let role, let interacting):
          if interacting {
            self.isInteracting = true
            self.interactingRole = role
            if !hasShownPeerEditToast {
              peerFrameGuidingToast(type: .edit)
              hasShownPeerEditToast = true
            }
          } else {
            self.isInteracting = false
            self.interactingRole = nil
          }

        default:
          break
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
    case .deleteAll:
      sendingEventType = .deleteAll
    }

    Task.detached { [weak self] in
      guard let self else { return }
      await self.networkService.send(for: .frameUpdated(sendingEventType))
    }
  }

  /// 프레임 토글 상태 전송
  private func sendFrameEnabled(_ enabled: Bool, _ currentRole: Role?) {
    Task.detached { [weak self] in
      guard let self else { return }
      await self.networkService.send(for: .frameEnabled(enabled, currentRole))
    }
  }

  /// 프레임 상호작용(제스처) 시작/종료 전송
  func sendFrameInteracting(_ interacting: Bool) {
    let myRole = currentRole ?? .photographer
    Task.detached { [weak self] in
      guard let self else { return }
      await self.networkService.send(for: .frameInteracting(role: myRole, isInteracting: interacting))
    }
  }
}

private enum FrameNetworkCommand {
  case add(frame: Frame)
  case move(frame: Frame)
  case modify(frame: Frame)
  case deleteAll
}
