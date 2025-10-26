import Foundation

enum FlashMode: Int {
  case off = 0
  case on
  case auto
}

protocol CamerSettingsServiceProtocol: AnyObject {
  var livePhotoOn: Bool { get set }
  var gridOn: Bool { get set }
  var flashMode: FlashMode { get set }
}
