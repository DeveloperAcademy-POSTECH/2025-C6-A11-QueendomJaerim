import SwiftUI

extension CameraView.CameraBottomContainer {
  var captureButton: some View {
    Group {
      if currentMode == .photographer {  // 작가 전용 뷰
        Button(action: {
          shutterActionEffect()
          cameraViewModel.capturePhoto()
        }) {
          ZStack {
            Circle()
              .fill(.gray900)
              .frame(width: isMinimize ? 40 : 80, height: isMinimize ? 40 : 80)

            Circle()
              .fill(.offWhite)
              .frame(width: isMinimize ? 28 : 68, height: isMinimize ? 28 : 68)
          }
          // 터치 영역 보정을 위해 투명 배경을 주고 싶다면 여기에 .contentShape(Circle()) 추가
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

#Preview {
  VStack {
    ZStack {
      Circle()
        .fill(.gray900)
        .frame(width: 80, height: 80)

      Circle()
        .fill(.offWhite)
        .frame(width: 68, height: 68)
    }
  }
  .frame(width: 300, height: 300)
  .background(.black)
}
