import Photos
import SwiftUI

struct PhotosPickerView {
  @Environment(\.dismiss) private var dismiss

  // 시트 내부 임시 상태 (썸네일/풀스크린에서만 바뀜)
  @State private var sheetSelectedImage: UIImage?
  @State private var sheetSelectedImageID: String?

  // 컬러 테마를 위해 Role을 알아야 함
  let roleForTheme: Role?

  // 상위 뷰에서 넘어오는 아이디
  @Binding var selectedImageID: String?

  let viewModel = PhotosViewModel()

  let onTapComplete: (UIImage?) -> Void

  @State private var selectedImageAsset: IdentifiableAsset?

  private let gridSpacing: CGFloat = 3
  private var columnList: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: 3)
  }
}

extension PhotosPickerView: View {
  var body: some View {
    VStack {
      switch viewModel.state {
      case .idle, .requestingPermission:
        ProgressView()
          .task {
            await viewModel.requestAccessAndLoad()
          }

      case .denied:
        VStack(spacing: 24) {
          Text("사진 보관함에 접근할 수 없어요. \n설정에서 사진 보관함 접근을 허용해주세요.")
            .typo(.m15)
            .foregroundStyle(.systemBlack)
            .multilineTextAlignment(.center)

          Button(action: {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
          }) {
            Text("설정으로 이동")
              .typo(.m15)
              .foregroundStyle(.gray900)
              .frame(width: 114, height: 39)
              .background(.gray200)
              .clipShape(.rect(cornerRadius: 22))
          }
        }

      case .loaded:
        NavigationStack {
          ScrollView {
            LazyVGrid(columns: columnList, spacing: gridSpacing) {
              ForEach(viewModel.assetList.indices, id: \.self) { index in
                let asset = viewModel.assetList[index]

                ThumbnailView(
                  asset: asset,
                  manager: viewModel.cachingManager,
                  isSelected: sheetSelectedImageID == asset.localIdentifier,
                  roleForTheme: roleForTheme,
                  onTapCheck: { fullImage in
                    // 선택된 상태에서 체크박스 탭하면 선택 해제
                    if sheetSelectedImageID == asset.localIdentifier {
                      sheetSelectedImage = nil
                      sheetSelectedImageID = nil
                    } else {
                      sheetSelectedImage = fullImage
                      sheetSelectedImageID = asset.localIdentifier
                    }
                  },
                  onTapThumbnail: { _ in
                    // 풀 스크린으로 이동
                    selectedImageAsset = IdentifiableAsset(asset: asset, selectedAssetIndex: index)
                  }
                )
                .aspectRatio(1.0, contentMode: .fill)
              }
            }
            .backgroundStyle(.gray400)
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
                Text("등록")
              }
              .disabled(sheetSelectedImageID == nil)
            }
          }
          .onAppear {
            sheetSelectedImageID = selectedImageID
            if selectedImageID == nil {
              sheetSelectedImage = nil
            }
          }
        }
        .fullScreenCover(item: $selectedImageAsset) { item in
          PhotoDetailView(
            assetList: viewModel.assetList,
            selectedIndex: item.selectedAssetIndex,
            manager: viewModel.cachingManager,
            selectedImageID: $sheetSelectedImageID,
            role: roleForTheme,
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
    .onChange(of: selectedImageID) { _, newValue in
      if newValue == nil {
        sheetSelectedImage = nil
        sheetSelectedImageID = nil
      } else {
        sheetSelectedImageID = newValue
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
