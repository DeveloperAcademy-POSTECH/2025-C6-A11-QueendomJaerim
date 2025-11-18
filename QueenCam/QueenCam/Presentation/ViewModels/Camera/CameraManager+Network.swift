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
  // 라이브 포토 비디오 저장 디렉토리 프리픽스
  private var livePhotoMoviesDirectoryName: String {
    "receivedLivePhotoMovies"
  }

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
    let isLivePhoto = videoData != nil

    if let videoData {
      handleLivePhotoEvent(photoData: photoData, videoData: videoData)
    } else {
      handleBasicPhotoEvent(photoData: photoData)
    }
  }

  private func handleLivePhotoEvent(photoData: Data, videoData: Data) {
    do {
      let path = try FileManager.default
        .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appendingPathComponent(livePhotoMoviesDirectoryName)

      try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)

      let fileURL = path.appendingPathComponent(UUID().uuidString)
        .appendingPathExtension(for: .quickTimeMovie)

      try videoData.write(to: fileURL)

      PhotoLibraryHelpers.saveLivePhotoToPhotosLibrary(stillImageData: photoData, livePhotoMovieURL: fileURL)
    } catch {
      logger.error("failed to prepare directory to save a live photo movie. error=\(error.localizedDescription)")
    }

    if let image = UIImage(data: photoData) {
      DispatchQueue.main.async {
        self.onPhotoCapture?(image)
      }
    } else {
      logger.error("failed to convert data to image")
    }
  }

  private func handleBasicPhotoEvent(photoData: Data) {
    if let image = UIImage(data: photoData) {
      PhotoLibraryHelpers.saveToPhotoLibrary(image)
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
  /// 이미지를 전송한다.
  func sendPhoto(_ photoOutput: PhotoOuput) {
    guard networkService.networkState == .host(.publishing) else {
      logger.warning("The client has a viewer role or is not publishing. Skipping sending photo.")
      return
    }

    Task.detached { [weak self] in
      switch photoOutput {
      case .basicPhoto(_, let imageData):
        await self?.networkService.send(for: .photoResult(imageData: imageData, videoData: nil))
      case .livePhoto(_, let imageData, let videoData):
        await self?.networkService.send(for: .photoResult(imageData: imageData, videoData: videoData))
      }
    }
  }
}
