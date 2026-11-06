import Foundation

final class CameraSettingsService: CameraSettingsServiceProtocol {
  private let livePhotoKey = "livePhotoOn"
  private let gridKey = "gridOn"
  private let flashKey = "flashMode"
  private let saveGuidingOverlayImageKey = "saveGuidingOverlayImageOn"
  private let photoAspectRatioKey = "photoAspectRatio"

  init() {
    UserDefaults.standard.register(defaults: [
      livePhotoKey: false,
      gridKey: false,
      flashKey: FlashMode.off.rawValue,
      saveGuidingOverlayImageKey: false,
      photoAspectRatioKey: PhotoAspectRatio.ratio4x3.rawValue
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

  var saveGuidingOverlayImageOn: Bool {
    get {
      UserDefaults.standard.bool(forKey: saveGuidingOverlayImageKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: saveGuidingOverlayImageKey)
    }
  }

  var photoAspectRatio: PhotoAspectRatio {
    get {
      UserDefaults.standard.string(forKey: photoAspectRatioKey).flatMap(PhotoAspectRatio.init(rawValue:)) ?? .ratio4x3
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: photoAspectRatioKey)
    }
  }
}
