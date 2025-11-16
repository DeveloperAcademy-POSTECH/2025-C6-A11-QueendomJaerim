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
    let onSingleTapAction: () -> Void  // 한번 탭

    @Binding var loadedImageList: [String: UIImage]
    @Binding var imageAspectRatioList: [String: CGFloat]

    @State private var detailImage: UIImage?  // 로드한 이미지를 담을 개별 상태
    @State private var livePhoto: PHLivePhoto?

    // 최종 확정된 배율 (손가락을 뗐을때)
    @State private var currentScale: CGFloat = 1.0
    // 현재 핀치 동작 중인 배율 (임시)
    @State private var gestureScale: CGFloat = 1.0

    // 최종 확정된 위치 (손가락을 뗐을때)
    @State private var currentOffset: CGSize = .zero

    // 줌(앵커) 전용 임시 보관함
    @State private var gestureOffset: CGSize = .zero

    // 이동(패닝) 전용 임시 보관함
    @State private var panOffset: CGSize = .zero

    @State private var containerSize: CGSize = .zero

    // 핀치(줌) 동작 중인지 확인하는 플래그
    @State private var isPinching: Bool = false

    private let logger = QueenLogger(category: "PhotoDetailView+ItemComponent")
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

        // 저화질이든 고화질이든 비율은 동일하므로 즉시 저장
        saveAspectRatio(image: result)

        if !isDegraded {
          // 고화질 로드에 성공하면 캐시 저장 (캐시에는 원본 고화질이 저장됨)
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

  // 확대된 상태에서 드래그 하면서 사진이 움직일 수 있는 범위 계산 로직
  private func applyOffsetBounds() {
    guard currentScale > 1.0 else {
      if currentScale == 1.0 {
        currentOffset = .zero
      }
      return
    }

    let viewWidth = containerSize.width
    let viewHeight = containerSize.height

    let scaledWidth = viewWidth * currentScale
    let scaledHeight = viewHeight * currentScale

    let maxOffsetX = (scaledWidth - viewWidth) / 2
    let maxOffsetY = (scaledHeight - viewHeight) / 2

    currentOffset.width = min(max(currentOffset.width, -maxOffsetX), maxOffsetX)
    currentOffset.height = min(max(currentOffset.height, -maxOffsetY), maxOffsetY)
  }

  // 본 이미지의 비율 저장
  private func saveAspectRatio(image: UIImage) {
    let aspectRatio = image.size.width / image.size.height

    // 이미 저장된 비율이 있으면 중복 저장 방지
    if imageAspectRatioList[asset.localIdentifier] == nil {
      imageAspectRatioList[asset.localIdentifier] = aspectRatio
      logger.debug("비율 저장: \(aspectRatio))")
    }
  }
}

extension PhotoDetailView.ItemComponent: View {
  var magnificationGesture: some Gesture {
    MagnifyGesture()
      .onChanged { value in
        isPinching = true

        // 배율 계산 및 제한 (최대 배율을 도달하면 그 이상 줌인이 안됌)
        // 손가락을 움직인 만큼 줌을 적용했을 때의 예상 배율
        // (최종 확정된 현재 배율 * 이번 동작으로 변경된 배율)
        let newVisualScale = currentScale * value.magnification

        // 허용할 제한된 줌 배율을 저장할 변수
        var newGestureScale: CGFloat

        if newVisualScale > 4.0 {
          newGestureScale = 4.0 / currentScale
        } else if newVisualScale < 1.0 {
          newGestureScale = 1.0 / currentScale
        } else {
          newGestureScale = value.magnification
        }

        gestureScale = newGestureScale

        /// 위치 계산
        let containerCenter = CGPoint(
          x: containerSize.width / 2,
          y: containerSize.height / 2
        )

        // 핀치를 시작한 지점이 정중앙에서 얼나마 떨어져 있는지(줌의 기준점)
        let anchor = CGPoint(
          x: value.startLocation.x - containerCenter.x,
          y: value.startLocation.y - containerCenter.y
        )

        // 이미지가 anchor를 기준으로 얼마나 당겨져야 하는지
        let pinchAnchorOffsetX = (anchor.x - currentOffset.width) * (1 - newGestureScale)
        let pinchAnchorOffsetY = (anchor.y - currentOffset.height) * (1 - newGestureScale)

        gestureOffset = CGSize(
          width: pinchAnchorOffsetX,
          height: pinchAnchorOffsetY
        )
      }
      .onEnded { _ in
        isPinching = false

        // 임시 배율을 최종 배율에 곱해서 확정
        currentScale *= gestureScale

        // 줌과 이동 임시 값을 모두 합쳐서 최종 위치에 확정
        currentOffset.width += gestureOffset.width + panOffset.width
        currentOffset.height += gestureOffset.height + panOffset.height

        gestureScale = 1.0
        gestureOffset = .zero
        panOffset = .zero

        if currentScale < 1.0 {
          currentScale = 1.0
        } else if currentScale > 4.0 {
          currentScale = 4.0
        }

        if currentScale == 1.0 {
          currentOffset = .zero
        }

        applyOffsetBounds()
      }
  }

  var dragGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        if currentScale > 1.0 || isPinching {
          panOffset = value.translation
        }
      }
      .onEnded { _ in
        if !isPinching {
          currentOffset.width += panOffset.width
          currentOffset.height += panOffset.height

          panOffset = .zero
          applyOffsetBounds()
        }
      }
  }

  var singleTapGesture: some Gesture {
    TapGesture(count: 1)
      .onEnded {
        onSingleTapAction()
      }
  }

  // 더블탭을 이용한 확대 축소
  var doubleTapGesture: some Gesture {
    SpatialTapGesture(count: 2)
      .onEnded { value in
        if currentScale > 1.0 {
          currentScale = 1.0
          currentOffset = .zero
        } else {
          let targetScale: CGFloat = 2.0

          // 해당 뷰의 정중앙
          let containerCenter = CGPoint(
            x: containerSize.width / 2,
            y: containerSize.height / 2
          )

          // 탭한 위치의 좌표
          let location = value.location

          // 수정 위치 계산
          let offSetX = (containerCenter.x - location.x)
          let offSetY = (containerCenter.y - location.y)

          currentScale = targetScale
          currentOffset = CGSize(width: offSetX, height: offSetY)

        }

        applyOffsetBounds()
      }
  }

  var body: some View {
    GeometryReader { proxy in

      ZStack {
        Color.black.ignoresSafeArea()

        Group {
          switch self.isLivePhoto {
          case true:
            if let livePhoto = livePhoto {
              LivePhotoView(livePhoto: livePhoto)
            } else if let image = detailImage {
              Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
              ProgressView()
            }

          case false:
            if let image = detailImage {
              Image(uiImage: image)
                .resizable()
                .scaledToFit()
            } else {
              ProgressView()
            }
          }
        }
        .scaleEffect(currentScale * gestureScale)
        .offset(
          x: currentOffset.width + gestureOffset.width + panOffset.width,
          y: currentOffset.height + gestureOffset.height + panOffset.height
        )
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .simultaneousGesture(doubleTapGesture.exclusively(before: singleTapGesture))
      .simultaneousGesture(magnificationGesture)
      .simultaneousGesture(
        currentScale > 1.0 ? dragGesture : nil
      )
      .onAppear {
        containerSize = proxy.size

        currentScale = 1.0
        currentOffset = .zero

        requestImage()

        if isLivePhoto {
          requestLivePhoto()
          requestVideoResouceData()
        }
      }
    }
  }
}
