import AVFoundation
import OSLog
import Photos
import UIKit

// MARK: - Photo Handlers
extension CameraDelegate {
  enum PhotoSaveType {
    case basic
    case proxy
  }
}

extension CameraDelegate {
  func handleBasicPhoto(
    imageData: Data,
    photoSaveType: PhotoSaveType,
    cropFailureMessage: String
  ) {
    /// 일반 사진 저장 파이프라인.
    /// 선택 비율로 still을 가공하고, 실패 시 원본으로 fallback 후 저장한다.
    let originalThumbnail = UIImage(data: imageData) ?? .init()

    if selectedPhotoAspectRatio == .ratio4x3 {
      saveImageDataToPhotoLibrary(imageData, photoSaveType: photoSaveType)
      completion(.basicPhoto(thumbnail: originalThumbnail, imageData: imageData))
      resetCaptureState()
      return
    }

    let sourceSize = sourceImageSize(from: imageData) ?? .zero
    let targetRatio = normalizedTargetRatio(
      selectedRatio: selectedPhotoAspectRatio.value,
      sourceSize: sourceSize
    )

    guard
      let cropped = croppedImageDataPreservingMetadata(
        imageData: imageData,
        targetRatio: targetRatio
      )
    else {
      logger.error("\(cropFailureMessage)")
      saveImageDataToPhotoLibrary(imageData, photoSaveType: photoSaveType)
      completion(.basicPhoto(thumbnail: originalThumbnail, imageData: imageData))
      return
    }

    saveImageDataToPhotoLibrary(cropped.imageData, photoSaveType: photoSaveType)
    completion(.basicPhoto(thumbnail: cropped.thumbnail, imageData: cropped.imageData))
    resetCaptureState()
  }

  func processLivePhotoStillImageData(imageData: Data) -> Data {
    /// 라이브 still(이미지)만 선택 비율로 가공한다.
    /// 실패 시 원본 still 데이터를 반환해 저장 실패를 방지한다.
    if selectedPhotoAspectRatio == .ratio4x3 {
      return imageData
    }

    let sourceSize = sourceImageSize(from: imageData) ?? .zero
    let targetRatio = normalizedTargetRatio(
      selectedRatio: selectedPhotoAspectRatio.value,
      sourceSize: sourceSize
    )

    guard
      let cropped = croppedImageDataPreservingMetadata(
        imageData: imageData,
        targetRatio: targetRatio
      )
    else {
      logger.error("Live still metadata-preserving crop failed. Fallback to original image data.")
      return imageData
    }

    return cropped.imageData
  }
  /// 촬영 사이에 남아 있는 임시 상태를 비운다.
  func resetCaptureState() {
    lastThumbnailImage = nil
    lastStillImageData = nil
    deferredPhotoProxyData = nil
    livePhotoMovieURL = nil
    isLivePhoto = false
  }
}

extension CameraDelegate {
  /// 일반/프록시 저장 타입에 맞는 저장 함수를 분기 호출한다.
  private func saveImageDataToPhotoLibrary(_ imageData: Data, photoSaveType: PhotoSaveType) {
    switch photoSaveType {
    case .basic:
      PhotoLibraryHelpers.saveToPhotoLibrary(imageData)
    case .proxy:
      PhotoLibraryHelpers.saveProxyToPhotoLibrary(imageData)
    }
  }
}
