import SwiftUI

struct CameraView {
  @State private var viewModel = CameraViewModel()
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
        
        Text("카메라 프리뷰 자리")
          .foregroundStyle(.white)
      case false:
        Color.black.ignoresSafeArea()
        
        Text("권한이 거부되었습니다.")
          .foregroundStyle(.white)
      }
      
      
    }
    .alert("카메라 접근 권한", isPresented: $viewModel.isShowSettingAlert, actions: {
      Button(role: .cancel, action: { })
      
      Button(action: {  openSetting() }) {
        Text("설정으로 이동")
      }
    }, message: {
      Text("설정에서 카메라 접근 권한을 허용해주세요.")
    })
    .task {
      await viewModel.checkPermission()
    }
    
  }
}
