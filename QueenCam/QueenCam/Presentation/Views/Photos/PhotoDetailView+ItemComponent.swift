import OSLog
import Photos
import PhotosUI
import SwiftUI

struct LivePhotoView: UIViewRepresentable {
  let livePhoto: PHLivePhoto

  func makeUIView(context: Context) -> PHLivePhotoView {
    let livePhotoView = PHLivePhotoView()
    livePhotoView.contentMode = .scaleAspectFit
    return livePhotoView
  }

  func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
    uiView.livePhoto = livePhoto
  }
}

extension PhotoDetailView {
  struct ItemComponent {
    let asset: PHAsset
    let manager: PHCachingImageManager

    @Binding var loadedImageList: [String: UIImage]

    @State private var detailImage: UIImage?  // 로드한 이미지를 담을 개별 상태
    @State private var livePhoto: PHLivePhoto?

    private let logger = Logger(
      subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam",
      category: "PhotoDetailView+ItemComponent"
    )
  }
}

extension PhotoDetailView.ItemComponent {
  private func requestImage() {
    logger.debug("일반 이미지 요청 시작")

    // 캐시를 먼저 확인하고 이미 있으면 해당 이미지를 사용 (함수를 다 돌필요 X)
    if let cachedImage = loadedImageList[asset.localIdentifier] {
      self.detailImage = cachedImage
      logger.debug("캐시된 이미지 사용")
      return
    }

    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .opportunistic
    options.resizeMode = .none

    manager.requestImage(
      for: asset,
      targetSize: PHImageManagerMaximumSize,
      contentMode: .aspectFit,
      options: options
    ) { result, info in
      if let result {
        self.detailImage = result
        let isDegraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
        self.logger.debug("\(isDegraded ? "저화질 썸네일 로드" : "고화질 원본 로드")")

        if !isDegraded {
          // 고화질 로드에 성공하면 캐시 저장 (캐시에는 원본 고화질이 저장됌)
          self.loadedImageList[asset.localIdentifier] = result
          self.logger.debug("고화질 원본 로드 및 캐시")
        }
      }
    }
  }

  private func requestLivePhoto() {
    logger.debug("라이브 포토 요청 시작")
    let options = PHLivePhotoRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .opportunistic
    manager.requestLivePhoto(
      for: asset,
      targetSize: PHImageManagerMaximumSize,
      contentMode: .aspectFit,
      options: options
    ) { result, info in
      if let result {
        let isDegraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false

        if !isDegraded {
          self.livePhoto = result
          self.logger.debug("고화질 라이브 포토 로드 완료")
        } else {
          self.logger.debug("저화질 라이브 포토 로드")
        }
      }
    }
  }

  private var isLivePhoto: Bool {
    asset.mediaSubtypes.contains(.photoLive)
  }

  private func requestVideoResouceData() {
    logger.debug("라이브 포토 Paired Video 사전 캐시 시작")

    // 비디오 리소스 찾기
    let resources = PHAssetResource.assetResources(for: asset)

    guard let videoResource = resources.first(where: { $0.type == .pairedVideo }) else {
      logger.warning("Paired Video 리스소를 찾을 수 없음")
      return
    }

    // 데이터 요청 옵션 설정
    let options = PHAssetResourceRequestOptions()
    options.isNetworkAccessAllowed = true

    // 데이터 요청 실행
    let manger = PHAssetResourceManager()

    manger.requestData(
      for: videoResource,
      options: options,
      dataReceivedHandler: { _ in }
    ) { error in
      if let error = error {
        self.logger.error("Paired Video 캐시 실패: \(error.localizedDescription)")
      } else {
        self.logger.debug("Paired Video 캐시 완료")
      }

    }
  }
}

extension PhotoDetailView.ItemComponent: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      Group {
        switch self.isLivePhoto {
        case true:
          if let livePhoto = livePhoto {
            LivePhotoView(livePhoto: livePhoto)
              .background(.red.opacity(0.2))
          } else if let image = detailImage {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(.green.opacity(0.2))

          } else {
            ProgressView()
          }

        case false:
          if let image = detailImage {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(.green.opacity(0.2))
          } else {
            ProgressView()
          }
        }
      }
    }
    .onAppear {
      requestImage()

      if isLivePhoto {
        requestLivePhoto()
        requestVideoResouceData()
      }
    }
  }
}
