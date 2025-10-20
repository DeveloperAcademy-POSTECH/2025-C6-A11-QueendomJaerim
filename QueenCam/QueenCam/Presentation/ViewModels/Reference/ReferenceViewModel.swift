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
  private(set) var image: UIImage?  // 선택된 레퍼런스 사진

  var state: ReferenceState = .open
  var dragOffset: CGSize = .zero  // 드래그 중 임시편차

  // MARK: - 네트워크
  let networkService: NetworkServiceProtocol
  var cancellables: Set<AnyCancellable> = []

  // MARK: - 드래그 Close(Fold) 제스쳐
  let foldThreshold: CGFloat = -30  // FIXME: fold(접힘) 전환 임계값 - 변경 예정
  let maxDrag: CGFloat = 60  // 최대 드래그 허용 범위(양수: 오른쪽, 음수: 왼쪽)

  init(
    networkService: NetworkServiceProtocol = DependencyContainer.defaultContainer.networkService
  ) {
    self.networkService = networkService

    bind()
  }

  // 드래그 중: 수평만 처리
  func dragChanged(_ value: DragGesture.Value) {
    let x = value.translation.width
    dragOffset = .init(width: min(x, maxDrag), height: 0)
  }
  // 드래그 끝: 임계값(foldThreshold) 넘기면 접힘
  func dragEnded() {
    if dragOffset.width <= foldThreshold {
      state = .close
    }
    withAnimation(.snappy) {
      dragOffset = .zero
    }
  }
  // MARK: - 드래그 Open(Unfold) 제스쳐
  func unFold() {
    withAnimation(.snappy) {
      state = .open
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
