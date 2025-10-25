import Foundation

enum FlashMode: Int {
  case off = 0
  case on
  case auto
}

final class CameraSettings {
  private let livePhotoKey = "livePhotoOn"
  private let gridKey = "gridOn"
  private let flashKey = "falshMode"

  init() {
    UserDefaults.standard.register(defaults: [
      livePhotoKey: false,
      gridKey: false,
      flashKey: FlashMode.off.rawValue,
    ])
  }

  var livePhotoOn: Bool {
    get {
      UserDefaults.standard.bool(forKey: livePhotoKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: livePhotoKey)
    }
  }

  var gridOn: Bool {
    get {
      UserDefaults.standard.bool(forKey: gridKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: gridKey)
    }
  }

  var flashMode: FlashMode {
    get {
      FlashMode(rawValue: UserDefaults.standard.integer(forKey: flashKey)) ?? .off
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: flashKey)
    }
  }
}
