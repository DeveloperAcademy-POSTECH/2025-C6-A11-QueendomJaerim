import SwiftUI

extension CameraView.CameraBottomContainer {
  var thumbnailButton: some View {
    Button(action: { isShowPhotoPicker.toggle() }) {
      if let image = cameraViewModel.lastImage {
        Image(uiImage: image)
          .resizable()
          .frame(width: isMinimize ? 24 : 48, height: isMinimize ? 24 : 48)
          .clipShape(Circle())
      } else {
        if let thumbnailImage = cameraViewModel.thumbnailImage {
          Image(uiImage: thumbnailImage)
            .resizable()
            .frame(width: isMinimize ? 24 : 48, height: isMinimize ? 24 : 48)
            .clipShape(Circle())
        } else {
          EmptyPhotoButton()
        }
      }
    }
  }
}
