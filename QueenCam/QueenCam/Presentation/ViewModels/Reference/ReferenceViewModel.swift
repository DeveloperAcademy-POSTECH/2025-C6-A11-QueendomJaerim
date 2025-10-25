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
  private(set) var image: UIImage?  // 선택된 레퍼런스 사진

  var state: ReferenceState = .open
  let foldThreshold: CGFloat = -50
  var dragOffset: CGSize = .zero  // 드래그 중 임시편차
  var location: ReferenceLocation = .topLeft
  var alignment: Alignment { location.alignment }
  

  // MARK: - Network
  let networkService: NetworkServiceProtocol
  var cancellables: Set<AnyCancellable> = []

  init(
    networkService: NetworkServiceProtocol = DependencyContainer.defaultContainer.networkService
  ) {
    self.networkService = networkService

    bind()
  }
  // MARK: - DRAG(for fold/unfold)
  func dragChanged(_ value: DragGesture.Value) {
    let x = value.translation.width
    let y = value.translation.height
    dragOffset = CGSize(width: x, height: y )
  }
  func dragEnded() {
    if ( location == .topLeft || location == .bottomLeft) {
      if dragOffset.width <= foldThreshold {
        state = .close
      }
    } else {
      if dragOffset.width >= -foldThreshold {
        state = .close
      }
    }
    withAnimation(.snappy) {
      dragOffset = .zero
    }
  }
  func unFold() {
    withAnimation(.snappy) {
      state = .open
      dragOffset = .zero
    }
  }
  // MARK: - DRAG(for location change)
  func updateLocation(end: CGPoint, size: CGSize) {
    let newLocation = ReferenceLocation.corner(point: end, size: size)
    withAnimation(.snappy) {
      location = newLocation
      dragOffset = .zero
    }
  }

  // MARK: - Reference 삭제
  func onDelete() {  // 초기화
    withAnimation(.snappy) {
      state = .delete
      image = nil
      state = .open
    }
    self.sendReferenceImageCommand(command: .remove)
  }

  func onRegister(uiImage: UIImage?) {
    guard let uiImage else { return }
    self.image = uiImage
    self.sendReferenceImageCommand(command: .register(image: uiImage))
  }
}

// MARK: Receiving network event
extension ReferenceViewModel {
  private func bind() {
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
  }

  private func handleReferenceImageEvent(eventType: ReferenceImageEventType) {
    switch eventType {
    case .register(let imageData):
      if let uiImage = UIImage(data: imageData) {
        self.image = uiImage
      }
    case .remove:
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
    } else {
      sendReferenceImageRemovedEvent()
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
}

private enum ReferenceNetworkCommand {
  case remove
  case register(image: UIImage)
}
