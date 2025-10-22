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

struct PhotoDetailView {
  let asset: PHAsset
  let manager: PHCachingImageManager
  let selectedImageID: String?  // 외부에서 주입 받은 이미지 아이디
  let onTapConfirm: (UIImage) -> Void  // 완료시 상위로 전달
  let onTapClose: () -> Void

  @State private var detailImage: UIImage?
  @State private var detailSelectedImageID: String?

  @State private var livePhoto: PHLivePhoto?

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "PhotoDetailView")
}

extension PhotoDetailView {
  private func requestImage() {
    logger.debug("일반 이미지 요청 시작")
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
      dataReceivedHandler: { _ in }) { error in
        if let error = error {
          self.logger.error("Paired Video 캐시 실패: \(error.localizedDescription)")
        } else {
          self.logger.debug("Paired Video 캐시 완료")
        }
            
      }
  }
}

extension PhotoDetailView: View {
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

      VStack {
        HStack {
          Spacer()
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
          .padding(.top, 128)

        }

        Spacer()
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

      if asset.mediaSubtypes.contains(.photoLive) {
        requestLivePhoto()
        requestVideoResouceData()
      }
    }
  }
}
