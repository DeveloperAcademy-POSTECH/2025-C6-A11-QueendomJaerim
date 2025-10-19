import Photos
import SwiftUI

struct PhotoDetailView {
  let asset: PHAsset
  let manager: PHCachingImageManager
  let selectedImageID: String? // 외부에서 주입 받은 이미지 아이디
  let onTapConfirm: (UIImage) -> Void  // 완료시 상위로 전달
  let onTapClose: () -> Void

  @State private var detailImage: UIImage?
  @State private var detailSelectedImageID: String?

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
        self.detailImage = result
      }
    }
  }
}

extension PhotoDetailView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      if let image = detailImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .overlay(alignment: .topTrailing) {

            Button(action: {
              if detailSelectedImageID == asset.localIdentifier {
                detailSelectedImageID = nil
              } else {
                detailSelectedImageID = asset.localIdentifier
              }
            }) {
              Image(systemName: detailSelectedImageID == asset.localIdentifier ? "checkmark.circle.fill" : "circle")
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
            if let image = detailImage,
               detailSelectedImageID == asset.localIdentifier
            {
              onTapConfirm(image)
            }
          }) {
            Text("완료")
              .foregroundStyle(.white)
              .padding()
          }
          .disabled(detailSelectedImageID != asset.localIdentifier)
        }
        .padding()

        Spacer()

      }
    }
    .onAppear {
      detailSelectedImageID = selectedImageID
      requestImage()
    }
  }
}
