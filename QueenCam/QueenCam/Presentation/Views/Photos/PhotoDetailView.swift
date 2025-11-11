import OSLog
import Photos
import PhotosUI
import SwiftUI

struct PhotoDetailView {
  // 상위로 부터 받는 데이터
  let assetList: [PHAsset]  // 스와이프할 전체 사진
  let selectedIndex: Int  // 선택한 사진의 인덱스 (순서)
  let manager: PHCachingImageManager
  @Binding var selectedImageID: String?  // 외부에서 주입 받은 이미지 아이디

  let role: Role?

  let onTapConfirm: (UIImage, String) -> Void  // 완료시 상위로 전달
  let onTapClose: () -> Void

  // 이 뷰에서만 사용할 상태
  @State private var currentIndex: Int?  // 현재 스와이프해서 보고 있는 사진 인덱스 (순서)
  @State private var loadedImageList: [String: UIImage] = [:]  // 캐시된 이미지 리스트들 원본 (사진 ID: 고화질 원본)

  @State private var imageAspectRatioList: [String: CGFloat] = [:]  // 각 이미지의 비율 딕셔너리 공유 (가져오는 사진의 비율을 가지고 툴바 색상 변경)

  // 한번 탭 UI 변경용
  @State private var isSingleTapped: Bool = true

  private let logger = QueenLogger(category: "PhotoDetailView")
}

extension PhotoDetailView {
  // 현재 인덱스의 PHAsset을 가져오는 프로퍼티
  private var currentAsset: PHAsset? {
    if let index = currentIndex,
      assetList.indices.contains(index)
    {
      return assetList[index]
    } else {
      return nil
    }
  }

  // 현재 Asset이 라이브 포토인지 확인하는 프로퍼티
  private var isLivePhoto: Bool {
    return currentAsset?.mediaSubtypes.contains(.photoLive) ?? false
  }

  private var currentAssetID: String? {
    return currentAsset?.localIdentifier
  }

  private var currentImageAspectRatio: CGFloat {
    guard let assetID = currentAssetID else { return 1.0 }
    return imageAspectRatioList[assetID] ?? 1.0
  }

  private var isOverlap: Bool {
    guard currentImageAspectRatio != 1.0 else { return false }

    // 0.7보다 작으면 세로로 긴 이미지로 판단 (16:9, 스크린샷 등)
    let isVerticalImage = currentImageAspectRatio < 0.7

    logger.debug("비율: \(currentImageAspectRatio), 세로형 이미지: \(isVerticalImage)")

    return isVerticalImage
  }
}

extension PhotoDetailView: View {
  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: .zero) {
        ForEach(assetList.indices, id: \.self) { index in
          let asset = assetList[index]
          ItemComponent(
            asset: asset,
            manager: manager,
            onSingleTapAction: { isSingleTapped.toggle() },
            loadedImageList: $loadedImageList,
            imageAspectRatioList: $imageAspectRatioList
          )
          .containerRelativeFrame(.horizontal)
          .id(index)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $currentIndex)
    .overlay(alignment: .top) {
      if isSingleTapped {
        VStack(spacing: .zero) {
          TopToolBarComponent(
            currentIndex: currentIndex ?? .zero,
            totalItemListCount: assetList.count,
            isActive: selectedImageID != nil,
            isOverlap: isOverlap,
            onTapBackAction: { onTapClose() },
            onTapRegisterAction: {
              if let confirmAssetID = selectedImageID,
                let confirmImage = loadedImageList[confirmAssetID]
              {
                onTapConfirm(confirmImage, confirmAssetID)
              }
            }
          )

          HStack(alignment: .top) {
            LiveIconComponent(isLivePhoto: isLivePhoto)

            Spacer()

            CheckCircleButton(
              isSelected: selectedImageID == currentAssetID,
              role: role,
              isLarge: true,
              didTap: {
                guard let assetID = currentAssetID else { return }

                if selectedImageID == assetID {
                  selectedImageID = nil
                } else {
                  selectedImageID = assetID
                }
              }
            )
          }
          .padding(.top, 16)
          .padding(.trailing, 18)
        }
        .ignoresSafeArea()
      }
    }

    .onAppear {
      self.currentIndex = selectedIndex
    }
  }
}
