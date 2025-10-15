import Photos
import SwiftUI

struct ThumbnailView {
  @State private var image: UIImage?
  @Environment(\.displayScale) private var displayScale

  let asset: PHAsset
  let manager: PHCachingImageManager
  let onTapAcion: (UIImage?) -> Void
}

extension ThumbnailView {
  private func requestThumbnail() {
    let targetSize = CGSize(width: 120 * displayScale, height: 120 * displayScale)

    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .exact
    options.isNetworkAccessAllowed = true

    manager.requestImage(
      for: asset,
      targetSize: targetSize,
      contentMode: .aspectFit,
      options: options
    ) { result, _ in
      if let result { self.image = result }
    }
  }
}

extension ThumbnailView: View {
  var body: some View {
    ZStack {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .clipped()
          .onTapGesture {
            onTapAcion(image)
          }
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.12))
          .overlay { ProgressView().controlSize(.mini) }
      }
    }
    .onAppear {
      requestThumbnail()
    }
  }
}
