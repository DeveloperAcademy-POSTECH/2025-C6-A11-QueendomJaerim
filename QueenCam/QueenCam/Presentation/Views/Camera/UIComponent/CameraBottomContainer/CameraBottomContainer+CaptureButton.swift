import SwiftUI

extension CameraView.CameraBottomContainer {
  var captureButton: some View {
    Group {
      if currentMode == .photographer {  // 작가 전용 뷰
        Button(action: {
          shutterActionEffect()
          cameraViewModel.capturePhoto()
        }) {
          Circle()
            .fill(.offWhite)
            .stroke(.gray900, lineWidth: 6)
            .frame(width: 80, height: 80)
        }
        .disabled(!cameraViewModel.isCaptureButtonEnabled)

        Spacer()

        Button(action: {
          Task {
            await cameraViewModel.switchCamera()
          }
        }) {

          Circle()
            .fill(.gray900)
            .frame(width: 48, height: 48)
            .overlay {
              Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
                .foregroundStyle(.offWhite)
            }
        }
      } else {
        ThumbsUpButton {
          thumbsUpViewModel.userTriggerThumbsUp()
        }
      }
    }
  }
}
