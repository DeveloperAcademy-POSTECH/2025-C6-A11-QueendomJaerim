import SwiftUI

extension CameraView.CameraBottomContainer {
  var thumbnailButton: some View {
    Button(action: {
      isShowPhotoPicker.toggle()
      switch activeTool {
      case .frame:
        frameViewModel.selectedFrameID = nil
        frameViewModel.requestFrameOwnership(false, currentRole)
      case .pen:
        penViewModel.saveStroke()
      case .magicPen:
        break
      case .none:
        break
      }
      activeTool = nil

    }) {
      if let thumbnailImage = cameraViewModel.thumbnailImage {
        Image(uiImage: thumbnailImage)
          .resizable()
          .scaledToFill()
          .frame(width: isMinimize ? 24 : 48, height: isMinimize ? 24 : 48)
          .clipShape(Circle())
      } else {
        EmptyPhotoButton()
      }
    }
  }
}
