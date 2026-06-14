//
//  CameraManager+Network.swift
//  QueenCam
//
//  Created by 임영택 on 10/20/25.
//

import AVFoundation
import Combine
import Foundation
import OSLog
import UIKit

// MARK: Configs
extension CameraManager {
  private var logger: QueenLogger {
    QueenLogger(category: "CameraManager+Network")
  }
}

// MARK: - Receive
extension CameraManager {
  func bind() {
    networkService.networkEventPublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] event in
        switch event {
        case .photoResult(let photoData, let videoData):
          self?.handlePhotoResultEvent(photoData: photoData, videoData: videoData)
        default: break
        }
      }
      .store(in: &cancellables)
  }

  func handlePhotoResultEvent(photoData: Data, videoData: Data?) {
    if let videoData {
      handleLivePhotoEvent(photoData: photoData, videoData: videoData)
    } else {
      handleBasicPhotoEvent(photoData: photoData)
    }
  }

  private func handleLivePhotoEvent(photoData: Data, videoData: Data) {
    PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(stillImageData: photoData, livePhotoMovieData: videoData)

    if let image = UIImage(data: photoData) {
      DispatchQueue.main.async {
        self.onPhotoCapture?(image)
      }
    } else {
      logger.error("failed to convert data to image")
    }
  }

  private func handleBasicPhotoEvent(photoData: Data) {
    PhotoLibraryHelpers.saveToPhotoLibrary(photoData)
    if let image = UIImage(data: photoData) {
      DispatchQueue.main.async {
        self.onPhotoCapture?(image)
      }
    } else {
      logger.error("failed to convert data to image")
    }
  }
}

// MARK: - Send
extension CameraManager {
  func saveAndSendPhoto(_ photoOutput: PhotoOuput) {
    let compositeOutput = globalSettingsService.saveGuidingOverlayImageOn
      ? strokePhotoOverlayComposer.makeCompositePhotoOutput(from: photoOutput)
      : nil

    savePhotoOutput(photoOutput)
    sendPhoto(photoOutput)

    guard let compositeOutput else { return }
    savePhotoOutput(compositeOutput)
    sendPhoto(compositeOutput)
  }

  private func savePhotoOutput(_ photoOutput: PhotoOuput) {
    switch photoOutput {
    case .basicPhoto(_, let imageData, let isProxy):
      if isProxy {
        PhotoLibraryHelpers.saveProxyToPhotoLibrary(imageData)
      } else {
        PhotoLibraryHelpers.saveToPhotoLibrary(imageData)
      }
    case .livePhoto(_, let imageData, let videoData, let isDeferred):
      if isDeferred {
        PhotoLibraryHelpers.saveDeferredLivePhotoToPhotosLibrary(proxyData: imageData, livePhotoMovieData: videoData)
      } else {
        PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(stillImageData: imageData, livePhotoMovieData: videoData)
      }
    }
  }

  /// 이미지를 전송한다.
  func sendPhoto(_ photoOutput: PhotoOuput) {
    let isConnected = networkService.networkState == .host(.publishing)
      || networkService.networkState == .viewer(.connected)
    guard isConnected else {
      logger.warning("The client is not connected. Skipping sending photo.")
      return
    }

    Task.detached { [weak self] in
      switch photoOutput {
      case .basicPhoto(_, let imageData, _):
        await self?.networkService.send(for: .photoResult(imageData: imageData, videoData: nil))
      case .livePhoto(_, let imageData, let videoData, _):
        await self?.networkService.send(for: .photoResult(imageData: imageData, videoData: videoData))
      }
    }
  }
}
