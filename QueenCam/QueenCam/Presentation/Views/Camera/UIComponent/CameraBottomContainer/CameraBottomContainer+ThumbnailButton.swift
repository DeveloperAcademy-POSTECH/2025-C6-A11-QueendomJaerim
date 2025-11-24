import SwiftUI

extension CameraView.CameraBottomContainer {
  var thumbnailButton: some View {
    Button(action: {
      isShowPhotoPicker.toggle()
      /// nil로만 만드는게 아니라 정보를 줘야함
      /// 그렇게 해야 프레임 같은 경우 상대방도 nil이 됌
      switch activeTool {
      case .frame:
        // 프레임 소유권 변경 및 초기화: 내가 해제하는 경우에만 owner 제거
        frameViewModel.selectedFrameID = nil  // 프레임 선택(isSelected) 초기화 => 제어 모드 종료
        frameViewModel.setFrame(false, nil)  // 상대편 프레임 비활성화 상태 제거(소유자 해제 전파)
      case .pen:
        // 펜툴 비활성화 시 세션 strokes들을 persistedStrokes에 저장
        penViewModel.saveStroke()
      case .maginPen:
        break
      case .none:
        break
      }
      activeTool = nil

    }) {
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
