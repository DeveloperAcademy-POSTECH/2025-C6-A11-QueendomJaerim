//
//  PhotoLiberaryHelpers.swift
//  QueenCam
//
//  Created by 임영택 on 10/19/25.
//

import Foundation
import OSLog
import Photos
import UIKit

struct PhotoLibraryHelpers {
  static let logger = QueenLogger(category: "PhotoLiberaryHelpers")

  static func saveToPhotoLibrary(_ imageData: Data) {
    PHPhotoLibrary.shared().performChanges({
      let creationRequest = PHAssetCreationRequest.forAsset()
      creationRequest.addResource(with: .photo, data: imageData, options: nil)
    }) { success, error in
      if success {
        self.logger.info("Image data saved successfully.")
      } else if let error {
        self.logger.error("Failed to save Image data: \(error.localizedDescription)")
      }
    }
  }

  static func saveProxyToPhotoLibrary(_ imageData: Data) {
    PHPhotoLibrary.shared().performChanges({
      let creationRequest = PHAssetCreationRequest.forAsset()
      creationRequest.addResource(with: .photoProxy, data: imageData, options: nil)
    }) { success, error in
      if success {
        self.logger.info("Proxy data saved successfully.")
      } else if let error {
        self.logger.error("Failed to save Proxy data: \(error.localizedDescription)")
      }
    }
  }

  static func saveLivePhotoToPhotosLibrary(stillImageData: Data, livePhotoMovieURL: URL) {
    PHPhotoLibrary.shared().performChanges({
      let creationRequest = PHAssetCreationRequest.forAsset()

      creationRequest.addResource(with: .photo, data: stillImageData, options: nil)

      let options = PHAssetResourceCreationOptions()
      options.shouldMoveFile = true
      creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoMovieURL, options: options)

    }) { success, error in
      if success {
        self.logger.info("Live Photo saved successfully.")
      } else if let error {
        self.logger.error("Failed to save Live Photo: \(error.localizedDescription)")
      }
    }
  }

  static func saveLivePhotoToPhotosLibrary(stillImageData: Data, livePhotoMovieData: Data) {
    do {
      let livePhotoMovieURL = try writeLivePhotoMovieDataToTemporaryFile(livePhotoMovieData)
      saveLivePhotoToPhotosLibrary(stillImageData: stillImageData, livePhotoMovieURL: livePhotoMovieURL)
    } catch {
      logger.error("Failed to prepare Live Photo movie file: \(error.localizedDescription)")
    }
  }

  static func saveDeferredLivePhotoToPhotosLibrary(proxyData: Data, livePhotoMovieURL: URL) {
    PHPhotoLibrary.shared().performChanges({
      let creationRequest = PHAssetCreationRequest.forAsset()

      creationRequest.addResource(with: .photoProxy, data: proxyData, options: nil)

      let options = PHAssetResourceCreationOptions()
      options.shouldMoveFile = true
      creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoMovieURL, options: options)

    }) { success, error in
      if success {
        self.logger.info("Deferred Live Photo saved successfully.")
      } else if let error {
        self.logger.error("Failed to save Deferred Live Photo: \(error.localizedDescription)")
      }
    }
  }

  static func saveDeferredLivePhotoToPhotosLibrary(proxyData: Data, livePhotoMovieData: Data) {
    do {
      let livePhotoMovieURL = try writeLivePhotoMovieDataToTemporaryFile(livePhotoMovieData)
      saveDeferredLivePhotoToPhotosLibrary(proxyData: proxyData, livePhotoMovieURL: livePhotoMovieURL)
    } catch {
      logger.error("Failed to prepare deferred Live Photo movie file: \(error.localizedDescription)")
    }
  }
}

private extension PhotoLibraryHelpers {
  static func writeLivePhotoMovieDataToTemporaryFile(_ movieData: Data) throws -> URL {
    // Live Photo 저장은 paired video 파일을 Photos 라이브러리로 이동시킨다.
    // 원본 Live Photo와 오버레이 합성 Live Photo를 함께 저장할 때 같은 movie URL을 재사용하면
    // 먼저 완료된 저장 요청이 파일을 이동시켜 나머지 저장 요청의 paired video가 사라진다.
    // 따라서 캡처된 movie data를 별도의 임시 파일로 복제해
    // 각 Live Photo asset이 독립적인 파일을 소유하게 한다.
    let livePhotoMovieURL = URL.movieFileURL
    try movieData.write(to: livePhotoMovieURL)
    return livePhotoMovieURL
  }
}
