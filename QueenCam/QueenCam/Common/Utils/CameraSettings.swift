import Foundation

final class CameraSettings {
  private let livePhotoKey = "livePhotoOn"
  private let gridKey = "gridOn"

  init() {
    // 기본값 등록
    UserDefaults.standard.register(defaults: [
      livePhotoKey: false,
      gridKey: false,
    ])
  }

  var livePhotoOn: Bool {
    get { UserDefaults.standard.bool(forKey: livePhotoKey) }
    set { UserDefaults.standard.set(newValue, forKey: livePhotoKey) }
  }

  var gridOn: Bool {
    get { UserDefaults.standard.bool(forKey: gridKey) }
    set { UserDefaults.standard.set(newValue, forKey: gridKey) }
  }
}
