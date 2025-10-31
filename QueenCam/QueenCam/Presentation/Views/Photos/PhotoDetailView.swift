import OSLog
import Photos
import PhotosUI
import SwiftUI

struct PhotoDetailView {
  // 상위로 부터 받는 데이터
  let assetList: [PHAsset]  // 스와이프할 전체 사진
  let selectedIndex: Int  // 선택한 사진의 인덱스 (순서)
  let manager: PHCachingImageManager
  let selectedImageID: String?  // 외부에서 주입 받은 이미지 아이디

  let onTapConfirm: (UIImage, String) -> Void  // 완료시 상위로 전달
  let onTapClose: () -> Void

  // 이 뷰에서만 사용할 상태
  @State private var currentIndex: Int?  // 현재 스와이프해서 보고 있는 사진 인덱스 (순서)
  @State private var detailSelectedImageID: String?  // 체크박스 상태 관리
  @State private var loadedImageList: [String: UIImage] = [:]  // 캐시된 이미지 리스트들 원본 (사진 ID: 고화질 원본)

  // 한번 탭 UI 변경용
  @State private var isSingleTapped: Bool = false

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "PhotoDetailView")
}

extension PhotoDetailView {
  private var currentAssetID: String? {
    if let index = currentIndex, assetList.indices.contains(index) {
      return assetList[index].localIdentifier
    } else {
      return nil
    }
  }
}

extension PhotoDetailView: View {
  var body: some View {
    ZStack {
      ScrollView(.horizontal) {
        LazyHStack(spacing: .zero) {
          ForEach(assetList.indices, id: \.self) { index in
            let asset = assetList[index]
            ItemComponent(
              asset: asset,
              manager: manager,
              onSingleTapAction: { isSingleTapped.toggle() },
              loadedImageList: $loadedImageList
            )
            .containerRelativeFrame(.horizontal)
            .id(index)
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.paging)
      .scrollPosition(id: $currentIndex)

      if isSingleTapped {
        VStack {
          HStack {
            Spacer()
            Button(action: {
              guard let assetID = currentAssetID else { return }

              if detailSelectedImageID == assetID {
                detailSelectedImageID = nil
              } else {
                detailSelectedImageID = assetID
              }

            }) {
              Image(systemName: detailSelectedImageID == currentAssetID ? "checkmark.circle.fill" : "circle")
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

            Text("\((currentIndex ?? .zero) + 1) / \(assetList.count)")
              .foregroundStyle(.white)
              .font(.headline)

            Spacer()

            Button(action: {
              if let confirmAssetID = detailSelectedImageID,
                let confirmImage = loadedImageList[confirmAssetID]
              {
                onTapConfirm(confirmImage, confirmAssetID)
              }
            }) {
              Text("완료")
                .foregroundStyle(.white)
                .padding()
            }
          }
          .padding()

          Spacer()

        }
      }
    }
    .onAppear {
      self.currentIndex = selectedIndex
      self.detailSelectedImageID = selectedImageID
    }
  }
}
