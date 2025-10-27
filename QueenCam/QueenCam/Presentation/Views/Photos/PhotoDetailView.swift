import OSLog
import Photos
import PhotosUI
import SwiftUI

struct LivePhotoView: UIViewRepresentable {
  let livePhoto: PHLivePhoto

  func makeUIView(context: Context) -> PHLivePhotoView {
    let livePhotoView = PHLivePhotoView()
    livePhotoView.contentMode = .scaleAspectFit
    return livePhotoView
  }

  func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
    uiView.livePhoto = livePhoto
  }
}

struct PhotoDetailView {
  // 상위로 부터 받는 데이터
  let assetList: [PHAsset]  // 스와이프할 전체 사진
  let selectedIndex: Int  // 선택한 사진의 인덱스 (순서)
  let manager: PHCachingImageManager
  let selectedImageID: String?  // 외부에서 주입 받은 이미지 아이디

  let onTapConfirm: (UIImage) -> Void  // 완료시 상위로 전달
  let onTapClose: () -> Void

  // 이 뷰에서만 사용할 상태
  @State private var currentIndex: Int?  // 현재 스와이프해서 보고 있는 사진 인덱스 (순서)
  @State private var detailSelectedImageID: String?  // 체크박스 상태 관리

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "PhotoDetailView")
}

extension PhotoDetailView {}

extension PhotoDetailView: View {
  var body: some View {
    ZStack {
      VStack {
        Button(action: { onTapClose() }) {
          Text("닫기")
        }
      }
    }
    .onAppear {
      self.currentIndex = selectedIndex
      self.detailSelectedImageID = selectedImageID

      logger.info("assetList: \(assetList)")
      logger.info("selectedIndex: \(selectedIndex)")
      logger.info("selcetedImageID: \(selectedImageID as NSObject?)")
    }
  }
}
