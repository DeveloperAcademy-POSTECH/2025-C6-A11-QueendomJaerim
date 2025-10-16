import Photos
import SwiftUI

struct PhotosPickerView {
  @Environment(\.dismiss) private var dismiss

  // 시트 내부 임시 상태 (썸네일/풀스크린에서만 바뀜)
  @State private var tempSelectedImage: UIImage?
  @State private var tempSelectedImageID: String?

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
              ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                ThumbnailView(
                  asset: asset,
                  manager: viewModel.cachingManager,
                  isSelected: tempSelectedImageID == asset.localIdentifier,
                  onTapCheck: { image in
                    // 선택되어있을때 탭하면 선택 해제 (체크박스)
                    if tempSelectedImageID == asset.localIdentifier {
                      tempSelectedImageID = nil
                      tempSelectedImage = nil
                    } else {
                      tempSelectedImageID = asset.localIdentifier
                      tempSelectedImage = image
                    }
                  },
                  onTapThumbnail: { _ in
                    // 디테일로 이동
                    selectedImageAsset = IdentifiableAsset(asset: asset)
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

                if tempSelectedImageID != selectedImageID {
                  onTapComplete(tempSelectedImage)
                  selectedImageID = tempSelectedImageID
                }
                dismiss()
              }) {
                Text("완료")
              }
              .disabled(tempSelectedImageID == nil)
            }
          }
          .onAppear {
            tempSelectedImageID = selectedImageID
          }
        }
        .fullScreenCover(item: $selectedImageAsset) { item in
          PhotoDetailView(
            asset: item.asset,
            manager: viewModel.cachingManager,
            initialSelectedID: tempSelectedImageID,
            onTapConfirm: { image in
              tempSelectedImage = image
              tempSelectedImageID = item.asset.localIdentifier
              onTapComplete(image)
              selectedImageID = tempSelectedImageID
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
}
