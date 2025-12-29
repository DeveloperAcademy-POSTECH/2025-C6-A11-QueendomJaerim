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
}
