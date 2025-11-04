import Foundation

final class CameraSettingsService: CameraSettingsServiceProtocol {
  private let livePhotoKey = "livePhotoOn"
  private let gridKey = "gridOn"
  private let flashKey = "flashMode"

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
