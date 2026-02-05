import Photos
import UIKit

final class PhotosLibraryObserver: NSObject, PHPhotoLibraryChangeObserver {
  private let cachingManager = PHCachingImageManager()
  private let logger = QueenLogger(category: "PhotosLibraryObserver")
  
  var onUpdate: ((UIImage?) -> Void)?
  var getCurrentScale: (() -> CGFloat)?
  
  override init() {
    super.init()
    PHPhotoLibrary.shared().register(self)
  }
  
  deinit {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
  }
  
  nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let scale = self.getCurrentScale?() ?? 1.0
      await self.fetchThumbnail(scale: scale)
    }
  }
  
  func loadThumbnail(scale: CGFloat) async {
    let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    
    guard status == .authorized || status == .limited else {
      logger.debug("사진 접근 권한 거부")
      return
    }
    
    await fetchThumbnail(scale: scale)
  }
}

extension PhotosLibraryObserver {
  private func fetchThumbnail(scale: CGFloat) async {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.fetchLimit = 1
    
    let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    
    guard let asset = result.firstObject else {
      logger.debug("가져올 사진 없음")
      return
    }
    
    await requestThumbnailImage(asset: asset, scale: scale)
  }
  
  private func requestThumbnailImage(asset: PHAsset, scale: CGFloat) async {
    let targetSize = CGSize(width: 48 * scale, height: 48 * scale)
    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .exact
    options.allowSecondaryDegradedImage = true
    options.isNetworkAccessAllowed = true
    
    cachingManager.requestImage(
      for: asset,
      targetSize: targetSize,
      contentMode: .aspectFill,
      options: options
    ) { [weak self] result, _ in
      if let result {
        self?.onUpdate?(result)
      }
    }
  }
}
