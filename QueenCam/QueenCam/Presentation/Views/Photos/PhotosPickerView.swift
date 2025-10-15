import Photos
import SwiftUI

struct PhotosPickerView {
  let viewModel = PhotosViewModel()
  private let columnList = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

  @Environment(\.dismiss) private var dismiss

  let onSelectAction: (UIImage?) -> Void
}

extension PhotosPickerView { }

extension PhotosPickerView: View {
  var body: some View {
    VStack {
      switch viewModel.state {
      case .idle, .requestingPermission:
        Text("사진 권한 요청 확인 중")
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
                  onTapAcion: { onSelectAction($0) }
                )
              }
            }
          }
          .navigationTitle("Photos")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button(action: { dismiss() }) {
                Image(systemName: "xmark")
              }
              .buttonStyle(.glassProminent)
            }
          }
        }
      }
    }

  }
}
