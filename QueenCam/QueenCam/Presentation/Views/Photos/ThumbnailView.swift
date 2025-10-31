import Photos
import SwiftUI

struct ThumbnailView {
  @State private var image: UIImage?
  @Environment(\.displayScale) private var displayScale

  let asset: PHAsset
  let manager: PHCachingImageManager
  var isSelected: Bool
  let roleForTheme: Role?

  let onTapCheck: (UIImage) -> Void
  let onTapThumbnail: (PHAsset) -> Void
  
  private let loadingPlaceholderFillColor = Color.gray.opacity(0.12)
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
      contentMode: .aspectFill,
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
            // 디테일 이동
            onTapThumbnail(asset)
          }
      } else {
        Rectangle()
          .fill(loadingPlaceholderFillColor)
          .overlay { ProgressView().controlSize(.mini) }
      }

      CheckCircleButton(isSelected: isSelected, role: roleForTheme, isLarge: false) {
        if let image = image {
          onTapCheck(image)
        }
      }
      .padding(6)
    }
    .onAppear {
      requestThumbnail()
    }
  }
}
