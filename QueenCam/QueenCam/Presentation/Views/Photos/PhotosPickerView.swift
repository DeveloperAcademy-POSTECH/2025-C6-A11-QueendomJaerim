import Photos
import SwiftUI

struct PhotosPickerView {
  @Environment(\.dismiss) private var dismiss
  @State private var selectedImage: UIImage?
  @Binding var selectedImageID: String?

  let viewModel = PhotosViewModel()

  private let columnList = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
  let onTapComplete: (UIImage?) -> Void

  @State private var isShowDetail = false
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
                  isSelected: selectedImageID == asset.localIdentifier,
                  onTapCheck: { image in
                    if selectedImageID == asset.localIdentifier {
                      selectedImage = nil
                      selectedImageID = nil
                    } else {
                      selectedImageID = asset.localIdentifier
                      selectedImage = image
                    }
                  },
                  onTapThumbnail: { image in
                    // 디테일로 이동
                    selectedImage = image
                    isShowDetail = true
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
                onTapComplete(selectedImage)
                dismiss()
              }) {
                Text("완료")
              }
              .disabled(selectedImage == nil)
            }
          }
          .onAppear {
            if let id = selectedImageID {
              selectedImageID = id
            }
          }
        }
        .fullScreenCover(isPresented: $isShowDetail) {
          if let image = selectedImage {
            PhotoDetailView(
              image: image,
              onTapAction: {
                onTapComplete(image)
                isShowDetail = false
              },
              onTapClose: {
                isShowDetail = false
              }
            )
          }
        }
      }
    }
  }
}
