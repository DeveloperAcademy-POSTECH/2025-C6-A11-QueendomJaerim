import PhotosUI
import SwiftUI

struct CameraView {
  @State private var viewModel = CameraViewModel()
  var wifiAwareViewModel: WifiAwareViewModel

  @State private var selectedItem: PhotosPickerItem?
  @State private var selectedImage: UIImage?

  @Environment(\.router) private var router
}

extension CameraView {
  private func openSetting() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}

extension CameraView: View {
  var body: some View {
    ZStack {
      switch viewModel.isPermissionGranted {
      case true:
        Color.black.ignoresSafeArea()

        // 임시 툴바. 커밋하지 말기!!!
        VStack {
          HStack {
            Spacer()

            Button {
              router.push(.establishConnection)
            } label: {
              Text("연결")
                .padding(8)
            }
            .glassEffect()
            
            Button {
              wifiAwareViewModel.didPingButtonTap()
            } label: {
              Text("핑")
                .padding(8)
            }
            .glassEffect()

            Spacer()
          }

          CameraPreview(session: viewModel.manager.session)
            .overlay(alignment: .topLeading) {
              if let image = selectedImage {
                Image(uiImage: image)
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(height: 250)
                  .clipShape(.rect(cornerRadius: 16))
                  .overlay(alignment: .topTrailing) {
                    Button(action: {
                      selectedImage = nil
                      selectedItem = nil
                    }) {
                      Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                    }
                  }
              }
            }

          HStack {
            PhotosPicker(selection: $selectedItem, matching: .images) {
              if let image = viewModel.lastImage {
                Image(uiImage: image)
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 60, height: 60)
                  .clipShape(.rect(cornerRadius: 8))
              } else {
                Rectangle()
                  .fill(.gray.opacity(0.2))
                  .frame(width: 60, height: 60)
                  .clipShape(.rect(cornerRadius: 8))
              }
            }

            Spacer()

            Button(action: { viewModel.capturePhoto() }) {
              Circle()
                .fill(.white)
                .frame(width: 70, height: 70)
                .overlay(
                  Circle().stroke(Color.black.opacity(0.8), lineWidth: 2)
                )
            }

            Spacer()

            Button(action: {}) {
              Image(systemName: "arrow.triangle.2.circlepath.camera")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
            }
          }
        }
      case false:
        Color.black.ignoresSafeArea()

        VStack {
          Text("권한이 거부되었습니다.")
            .foregroundStyle(.white)

          Button(action: { openSetting() }) {
            Text("설정으로 이동하기")
          }
        }
      }
    }
    .alert(
      "카메라 접근 권한",
      isPresented: $viewModel.isShowSettingAlert,
      actions: {
        Button(role: .cancel, action: {})

        Button(action: { openSetting() }) {
          Text("설정으로 이동")
        }
      },
      message: {
        Text("설정에서 카메라 접근 권한을 허용해주세요.")
      }
    )
    .task {
      await viewModel.checkPermission()
      await viewModel.checkPhotosPermission()
    }
    .onChange(of: selectedItem) { _, new in
      Task {
        guard
          let data = try await new?.loadTransferable(type: Data.self),
          let image = UIImage(data: data)
        else { return }

        selectedImage = image
      }
    }
  }
}
