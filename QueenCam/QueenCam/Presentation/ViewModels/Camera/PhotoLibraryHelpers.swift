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

  static func saveToPhotoLibrary(_ image: UIImage) {
    PHPhotoLibrary.shared().performChanges {
      PHAssetChangeRequest.creationRequestForAsset(from: image)
    } completionHandler: { success, error in
      if success {
        self.logger.info("Image saved to gallery.")
      } else if error != nil {
        self.logger.error("Error saving image to gallery")
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
}
