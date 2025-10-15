import Photos
import SwiftUI

struct ThumbnailView {
  @State private var image: UIImage?
  @Environment(\.displayScale) private var displayScale

  let asset: PHAsset
  let manager: PHCachingImageManager
  var isSelected: Bool
  
  let onTapCheck: (UIImage) -> Void
  let onTapThumbnail: (UIImage) -> Void
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
    ZStack(alignment: .topTrailing) {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .clipped()
          .onTapGesture {
            onTapThumbnail(image)
          }
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.12))
          .overlay { ProgressView().controlSize(.mini) }
      }
      Button(action: {
        if let image = image {
          onTapCheck(image)
        }
      }) {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .imageScale(.large)
          .foregroundStyle(isSelected ? .blue : .gray.opacity(0.4))
          .padding(12)
          .background(.red.opacity(0.3))
      }
    }
    .onAppear {
      requestThumbnail()
    }
  }
}
