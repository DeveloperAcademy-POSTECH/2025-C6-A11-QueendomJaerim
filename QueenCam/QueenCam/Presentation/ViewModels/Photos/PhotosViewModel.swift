import Foundation
import Photos
import UIKit

@Observable
final class PhotosViewModel {
  enum State {
    case idle
    case requestingPermission
    case denied
    case loaded
  }

  var state: State = .idle
  var assetList: [PHAsset] = []

  let cachingManager = PHCachingImageManager()
  private var fetchResult: PHFetchResult<PHAsset>?

  func requestAccessAndLoad() async {
    guard state == .idle else { return }
    state = .requestingPermission

    let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    guard status == .authorized || status == .limited else {
      state = .denied
      return
    }

    fetchAllPhotos()
    state = .loaded
  }
}

extension PhotosViewModel {
  private func fetchAllPhotos() {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)

    var tmp: [PHAsset] = []
    tmp.reserveCapacity(result.count)
    result.enumerateObjects { asset, _, _ in
      tmp.append(asset)
    }

    self.fetchResult = result
    self.assetList = tmp
  }

  func startImageCaching(scale: CGFloat) {
    guard !assetList.isEmpty else { return }

    cachingManager.startCachingImages(
      for: assetList,
      targetSize: .init(width: 120 * scale, height: 120 * scale),
      contentMode: .aspectFit,
      options: .none
    )
  }

  func stopImageCaching() {
    cachingManager.stopCachingImagesForAllAssets()
  }
}
