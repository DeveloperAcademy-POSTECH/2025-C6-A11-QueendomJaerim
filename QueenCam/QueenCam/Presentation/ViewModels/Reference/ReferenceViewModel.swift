//
//  ReferenceViewModel.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//  Reference의 Open/Close 제스쳐 관리 ViewModel

import Combine
import Foundation
import SwiftUI
import UIKit

@Observable
final class ReferenceViewModel {
  // MARK: - Properties
  /// 선택된 레퍼런스 사진
  private(set) var image: UIImage?
  var state: ReferenceState = .none
  let foldThreshold: CGFloat = -50
  var dragOffset: CGSize = .zero  // 드래그 중 임시편차
  var location: ReferenceLocation = .topLeft
  var alignment: Alignment { location.alignment }
  /// CloseView의 위치 계산에 사용될 레퍼런스 높이
  var referenceHeight: CGFloat = 0

  /// 현재 레퍼런스 존재 여부
  var hasReferenceImage: Bool {
    image != nil
  }
  /// 현재 레퍼런스 토스트 존재 여부
  var hasReferenceToast: Bool = false

  /// 레퍼런스 최초 등록 여부
  private var firstRegisterReference: Bool = false

  // MARK: - Network
  let networkService: NetworkServiceProtocol
  var cancellables: Set<AnyCancellable> = []

  // MARK: - Toast State
  private let notificationService: NotificationServiceProtocol

  init(
    networkService: NetworkServiceProtocol = DependencyContainer.defaultContainer.networkService,
    notificationService: NotificationServiceProtocol = DependencyContainer.defaultContainer.notificationService
  ) {
    self.networkService = networkService
    self.notificationService = notificationService
    self.hasReferenceToast = (notificationService.currentNotification != nil)

    bind()
  }
  // MARK: - DRAG(for fold/unfold)
  func dragChanged(_ value: DragGesture.Value) {
    let x = value.translation.width
    let y = value.translation.height
    dragOffset = CGSize(width: x, height: y)
  }

  func dragEnded() {
    if location == .topLeft || location == .bottomLeft {
      if dragOffset.width <= foldThreshold {
        state = .close
      } else {
        state = .open
      }
    } else {
      if dragOffset.width >= -foldThreshold {
        state = .close
      } else {
        state = .open
      }
    }
    withAnimation(.snappy) {
      dragOffset = .zero
    }
  }
  /// CloseView에서의 버튼 누를때 액션
  func unFold() {
    state = .open
    dragOffset = .zero
  }

  // MARK: - DRAG(for location change)
  func updateLocation(end: CGPoint, size: CGSize, isLarge: Bool) {
    let newLocation = ReferenceLocation.corner(point: end, size: size)
    withAnimation(.snappy) {
      // 레퍼런스가 확대되었을때, corner 이동 금지
      if !isLarge {
        location = newLocation
      }
      dragOffset = .zero
    }
  }

  // MARK: - Reference 삭제
  func onDelete() {  // 삭제
    image = nil
    state = .none
    notificationService.registerNotification(.make(type: .deleteReference))

    // Send to Network
    self.sendReferenceImageCommand(command: .remove)
  }

  func onReset() {  // 초기화(역할 바꾸기, 연결 종료)
    image = nil
    state = .none

    // Send to Network
    self.sendReferenceImageCommand(command: .reset)
  }

  func onRegister(uiImage: UIImage?) {
    guard let uiImage else { return }
    self.image = uiImage
    state = .open

    // Send to Network
    self.sendReferenceImageCommand(command: .register(image: uiImage))
  }
}

// MARK: - Receiving network/notification event
extension ReferenceViewModel {
  private func bind() {
    // 네트워크 이벤트 구독
    networkService.networkEventPublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] event in
        switch event {
        case .referenceImage(let eventType):
          self?.handleReferenceImageEvent(eventType: eventType)
        default: break
        }
      }
      .store(in: &cancellables)

    // 토스트(도메인 알림) 변경 구독
    notificationService.lastNotificationPublisher
      .receive(on: RunLoop.main)
      .sink { [weak self] notification in
        withAnimation(.bouncy(duration: 0.6)) {
          self?.hasReferenceToast = (notification != nil)
        }
      }
      .store(in: &cancellables)
  }

  private func handleReferenceImageEvent(eventType: ReferenceImageEventType) {
    switch eventType {
    case .register(let imageData):
      if let uiImage = UIImage(data: imageData) {
        self.image = uiImage
        self.state = .open
      }
      if !firstRegisterReference && networkService.mode != nil {
        notificationService.registerNotification(.make(type: .peerRegisterFirstReference))
        firstRegisterReference = true
      } else {
        notificationService.registerNotification(.make(type: .peerRegisterNewReference))
      }
    case .remove:
      self.image = nil
      notificationService.registerNotification(.make(type: .peerDeleteReference))
    case .reset:
      self.image = nil
    }
  }
}

// MARK: Sending network event
extension ReferenceViewModel {
  nonisolated var compressionQualityOfReferenceImage: CGFloat { 0.8 }

  private func sendReferenceImageCommand(command: ReferenceNetworkCommand) {
    if case .register(let image) = command {
      sendReferenceImageRegisteredEvent(referenceImage: image)
      if !firstRegisterReference && networkService.mode != nil {
        notificationService.registerNotification(.make(type: .registerFirstReference))
        firstRegisterReference = true
      } else {
        notificationService.registerNotification(.make(type: .registerNewReference))
      }
    } else if case .remove = command {
      sendReferenceImageRemovedEvent()
    } else {
      sendReferenceImageResetEvent()
    }
  }

  private func sendReferenceImageRegisteredEvent(referenceImage: UIImage) {
    Task.detached { [weak self] in
      guard let self,
        let imageData = referenceImage.jpegData(compressionQuality: self.compressionQualityOfReferenceImage)
      else {
        return
      }
      await self.networkService.send(for: .referenceImage(.register(imageData: imageData)))
    }
  }

  private func sendReferenceImageRemovedEvent() {
    Task.detached { [weak self] in
      guard let self else { return }
      await self.networkService.send(for: .referenceImage(.remove))
    }
  }

  private func sendReferenceImageResetEvent() {
    Task.detached { [weak self] in
      guard let self else { return }
      await self.networkService.send(for: .referenceImage(.reset))
    }
  }

}

private enum ReferenceNetworkCommand {
  case remove
  case register(image: UIImage)
  case reset
}
