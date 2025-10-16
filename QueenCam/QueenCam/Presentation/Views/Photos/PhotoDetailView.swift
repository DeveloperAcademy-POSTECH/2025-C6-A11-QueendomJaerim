import Photos
import SwiftUI

struct PhotoDetailView {
  let asset: PHAsset
  let manager: PHCachingImageManager
  let initialSelectedID: String?
  let onTapConfirm: (UIImage) -> Void  // 완료시 상위로 전달
  let onTapClose: () -> Void

  @State private var fullScreenImage: UIImage?
  @State private var localSelectedID: String?

}

extension PhotoDetailView {
  private func requestImage() {
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .none
    manager.requestImage(
      for: asset,
      targetSize: PHImageManagerMaximumSize,
      contentMode: .aspectFit,
      options: options
    ) { result, _ in
      if let result {
        self.fullScreenImage = result
      }
    }
  }
}

extension PhotoDetailView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      if let image = fullScreenImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .overlay(alignment: .topTrailing) {

            Button(action: {
              if localSelectedID == asset.localIdentifier {
                localSelectedID = nil
              } else {
                localSelectedID = asset.localIdentifier
              }
            }) {
              Image(systemName: localSelectedID == asset.localIdentifier ? "checkmark.circle.fill" : "circle")
                .imageScale(.large)
                .padding()
            }
          }
      }

      VStack {
        HStack {
          Button(action: { onTapClose() }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title)
              .foregroundStyle(.white.opacity(0.9))
          }

          Spacer()

          Button(action: {
            if let image = fullScreenImage,
              localSelectedID == asset.localIdentifier
            {
              onTapConfirm(image)
            }
          }) {
            Text("완료")
              .foregroundStyle(.white)
              .padding()
          }
          .disabled(localSelectedID != asset.localIdentifier)
        }
        .padding()

        Spacer()

      }
    }
    .onAppear {
      localSelectedID = initialSelectedID
      requestImage()
    }
  }
}
