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
            .frame(width: isMinimize ? 40 : 80, height: isMinimize ? 40 : 80)
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
            .frame(width: isMinimize ? 24 : 48, height: isMinimize ? 24 : 48)
            .overlay {
              Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isMinimize ? 13 : 26, height: isMinimize ? 13 : 26)
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
