import Photos
import SwiftUI

struct PhotosPickerView {
  @Environment(\.dismiss) private var dismiss

  // 시트 내부 임시 상태 (썸네일/풀스크린에서만 바뀜)
  @State private var sheetSelectedImage: UIImage?
  @State private var sheetSelectedImageID: String?

  // 상위 뷰에서 넘어오는 아이디
  @Binding var selectedImageID: String?

  let viewModel = PhotosViewModel()

  private let columnList = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

  let onTapComplete: (UIImage?) -> Void

  @State private var selectedImageAsset: IdentifiableAsset?

}

extension PhotosPickerView: View {
  var body: some View {
    VStack {
      switch viewModel.state {
      case .idle, .requestingPermission:
        ProgressView("사진 권한 요청 확인 중")
          .task {
            await viewModel.requestAccessAndLoad()
          }

      case .denied:
        Text("사진 권한 거부")

      case .loaded:
        NavigationStack {
          ScrollView {
            LazyVGrid(columns: columnList, spacing: 1) {
              ForEach(viewModel.assetList.indices, id: \.self) { index in
                let asset = viewModel.assetList[index]

                ThumbnailView(
                  asset: asset,
                  manager: viewModel.cachingManager,
                  isSelected: sheetSelectedImageID == asset.localIdentifier,
                  onTapCheck: { image in
                    // 선택된 상태에서 체크박스 탭하면 선택 해제
                    if sheetSelectedImageID == asset.localIdentifier {
                      sheetSelectedImage = nil
                      sheetSelectedImageID = nil
                    } else {
                      sheetSelectedImage = image
                      sheetSelectedImageID = asset.localIdentifier
                    }
                  },
                  onTapThumbnail: { _ in
                    // 풀 스크린으로 이동
                    selectedImageAsset = IdentifiableAsset(asset: asset, selectedAssetIndex: index)
                  }
                )
              }
            }
          }
          .navigationTitle("Photos")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button(action: {
                dismiss()
              }) {
                Image(systemName: "xmark")
              }
            }

            ToolbarItem(placement: .topBarTrailing) {
              Button(action: {

                if sheetSelectedImageID != selectedImageID {
                  onTapComplete(sheetSelectedImage)
                  selectedImageID = sheetSelectedImageID
                }
                dismiss()
              }) {
                Text("완료")
              }
              .disabled(sheetSelectedImageID == nil)
            }
          }
          .onAppear {
            sheetSelectedImageID = selectedImageID
          }
        }
        .fullScreenCover(item: $selectedImageAsset) { item in
          PhotoDetailView(
            assetList: viewModel.assetList,
            selectedIndex: item.selectedAssetIndex,
            manager: viewModel.cachingManager,
            selectedImageID: sheetSelectedImageID,
            onTapConfirm: { image, assetID in
              sheetSelectedImage = image
              sheetSelectedImageID = assetID
              onTapComplete(image)
              selectedImageID = sheetSelectedImageID
              selectedImageAsset = nil
              dismiss()
            },
            onTapClose: {
              selectedImageAsset = nil
            }
          )
        }
      }
    }
  }
}

// 바인딩을 위한 Identifiable 모델
struct IdentifiableAsset: Identifiable {
  var id: String {
    asset.localIdentifier
  }

  let asset: PHAsset
  let selectedAssetIndex: Int
}
