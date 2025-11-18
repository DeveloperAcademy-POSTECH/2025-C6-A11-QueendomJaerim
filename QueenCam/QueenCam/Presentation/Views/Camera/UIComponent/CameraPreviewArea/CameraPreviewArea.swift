import AVKit
import PhotosUI
import SwiftUI
import WiFiAware

extension CameraView {
  struct CameraPreviewArea {
    @State var isFocused = false
    @State var focusLocation: CGPoint = .zero
    @State var isReferenceLarge: Bool = false  // 레퍼런스 확대 축소 프로퍼티
    @State var zoomScaleItemList: [CGFloat] = [0.5, 1, 2]
    // 현재 적용된 줌 배율 (카메라와 UI 상태 동기화용)
    @State var currentZoomFactor: CGFloat = 1.0
    // 현재 하나의 핀치 동작 내에서 이전 배율 값을 임시 저장 (변화량을 계산하기 위해)
    @State var previousMagnificationValue: CGFloat = 1.0

    let cameraViewModel: CameraViewModel
    let previewModel: PreviewModel
    let penViewModel: PenViewModel
    let frameViewModel: FrameViewModel
    let referenceViewModel: ReferenceViewModel
    @Bindable var thumbsUpViewModel: ThumbsUpViewModel

    @Binding var activeTool: ActiveTool?

    @Binding var isShowShutterFlash: Bool

    @Binding var isShowCameraSettingTool: Bool

    /// 눈까리
    @Binding var isRemoteGuideHidden: Bool

    // connectionViewModel -> 프로퍼티 변환
    let currentRole: Role?
    let connectionLost: Bool
    let reconnectCancelButtonDidTap: () -> Void

    // 캡처시 화면 깜빡임 액션관리
    let shutterActionEffect: () -> Void
  }
}

extension CameraView.CameraPreviewArea {
  var currentMode: Role {
    self.currentRole ?? .photographer
  }

  var isFront: Bool {
    cameraViewModel.cameraPostion == .front
  }

  var activeZoom: CGFloat {
    switch currentZoomFactor {
    case ..<0.95:
      return 0.5
    case ..<1.95:
      return 1
    default:
      return 2
    }
  }

  var guideToggleImage: String {
    isRemoteGuideHidden ? "eye.slash" : "eye"
  }
}

extension CameraView.CameraPreviewArea: View {
  var body: some View {
    // 카메라 프리뷰
    ZStack {
      // MARK: 카메라 프리뷰
      previewContent

      // MARK: 레퍼런스 이미지가 isLarge 모드일 때 뒤에 깔리는 디밍
      largeReferenceImageDimmingLayer

      // MARK: 그리드
      if cameraViewModel.isShowGrid {
        GridView()
      }

      // MARK: 가이딩 툴 캔버스
      guidingLayer

      // MARK: 렌즈 배율 컨트롤
      lensZoomLayer

      // MARK: 카메라 바구니 토글 버튼과 눈까리 버튼
      toggleButtonsLayer

      // MARK: 레퍼런스 이미지 뷰
      ReferenceView(referenceViewModel: referenceViewModel, isLarge: $isReferenceLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .clipped()

      // MARK: 연결 유실시 재연결 뷰
      if connectionLost {
        ReconnectingView(didCancelButtonTap: reconnectCancelButtonDidTap)
      }
    }
    .aspectRatio(3 / 4, contentMode: .fill)
    .clipped()
    .clipShape(.rect(cornerRadius: 5))
    // MARK: Overlays
    // MARK: Overlays - 테두리 그래픽 요소
    .overlay {
      RoundedRectangle(cornerRadius: 5)
        .inset(by: 0.5)
        .stroke(Color.gray900, lineWidth: 1)
    }
    // MARK: Overlays - 토스트 오버레이
    .overlay(alignment: .center) {
      if !connectionLost {
        StateToastContainer()
          .padding(.top, 16)
      }
    }
    // MARK: Overlays - 따봉 버튼 애니메이션
    // 따봉 버튼 눌렀을 때 나올 뷰 => 둘다 표현해야 되기 때문에 따로 분기 처리 X
    .overlay(alignment: .bottom) {
      ThumbsUpView(trigger: $thumbsUpViewModel.animationTriger)
        .opacity(thumbsUpViewModel.isShowInitialView ? 1 : .zero)
    }
    .padding(.horizontal, 16)
  }
}
