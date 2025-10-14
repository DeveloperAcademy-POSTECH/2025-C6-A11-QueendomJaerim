import PhotosUI
import SwiftUI

struct CameraView {
  @State private var viewModel = CameraViewModel()
  var previewModel: PreviewStreamingViewModel
  @Environment(\.router) private var router
  
  // User Role
  let role: Role?

  @State private var selectedItem: PhotosPickerItem?
  @State private var selectedImage: UIImage?

  @State private var zoomScaleItemList: [CGFloat] = [0.5, 1, 2]

  @State private var isShowGrid: Bool = false

  @State private var isFocused = false
  @State private var focusLocation: CGPoint = .zero
}

extension CameraView {
  private func openSetting() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }

  private var isFront: Bool {
    viewModel.cameraPostion == .front
  }

  private var flashImage: String {
    switch viewModel.currentFlashMode {
    case .off:
      return "bolt.slash"
    case .on:
      return "bolt.fill"
    case .auto:
      return "bolt.badge.a"
    @unknown default:
      return "bolt.slash"
    }
  }

  private var isPermissionGranted: Bool {
    viewModel.isCameraPermissionGranted && viewModel.isCameraPermissionGranted
  }
}

extension CameraView: View {
  var body: some View {
    ZStack {
      switch isPermissionGranted {
      case true:
        Color.black.ignoresSafeArea()

        VStack {
          HStack {
            Button(action: { viewModel.switchFlashMode() }) {
              Image(systemName: flashImage)
                .foregroundStyle(viewModel.currentFlashMode == .on ? .yellow : .white)
            }

            Button(action: { viewModel.switchLivePhoto() }) {
              Image(systemName: viewModel.isLivePhotoOn ? "livephoto" : "livephoto.slash")
                .foregroundStyle(viewModel.isLivePhotoOn ? .yellow : .white)
            }

            Spacer()
            

            Button {
              router.push(.establishConnection)
            } label: {
              Text("연결")
                .padding(8)
            }
            .glassEffect()

            Spacer()

            Button(action: { isShowGrid.toggle() }) {
              Text(isShowGrid ? "그리드 활성화" : "그리드 비활성화")
                .foregroundStyle(isShowGrid ? .yellow : .white)
            }
          }
          .padding()

          ZStack {
            if role == nil || role == .photographer {
              CameraPreview(session: viewModel.manager.session)
                .aspectRatio(3 / 4, contentMode: .fit)
                .onTapGesture { location in
                  isFocused = true
                  focusLocation = location
                  viewModel.setFocus(point: location)
                }
                .overlay {
                  if isFocused {
                    FocusView(position: $focusLocation)
                      .onAppear {
                        withAnimation {
                          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            self.isFocused = false

                          }
                        }
                      }
                  }
                }
            } else {
              PreviewPlayerView(previewModel: previewModel)
            }

            if isShowGrid {
              GridView()
                .aspectRatio(3 / 4, contentMode: .fit)
            }

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

          if !isFront {
            HStack(spacing: 20) {
              ForEach(zoomScaleItemList, id: \.self) { item in
                Button(action: { viewModel.zoom(factor: item) }) {
                  Text(String(format: "%.1fx", item))

                    .foregroundStyle(viewModel.selectedZoom == item ? .yellow : .white)
                }
              }
            }
            .padding(.bottom, 32)
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

            Button(action: {
              Task {
                await viewModel.switchCamera()
              }
            }) {
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
        Button(role: .cancel, action: {}) {}

        Button(action: { openSetting() }) {
          Text("설정으로 이동")
        }
      },
      message: {
        Text("설정에서 카메라 접근 권한을 허용해주세요.")
      }
    )
    .task {
      await viewModel.checkPermissions()
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

struct FocusView: View {
  @Binding var position: CGPoint

  var body: some View {
    Rectangle()
      .frame(width: 70, height: 70)
      .foregroundStyle(.clear)
      .border(Color.yellow, width: 1.5)
      .position(x: position.x, y: position.y)
  }
}
