import Foundation

enum PhotoAspectRatio: String, CaseIterable {
  case ratio16x9 = "16:9"
  case ratio1x1 = "1:1"
  case ratio4x3 = "4:3"
}

extension PhotoAspectRatio {
  var value: CGFloat {
    switch self {
    case .ratio16x9:
      return 16.0 / 9.0
    case .ratio1x1:
      return 1.0
    case .ratio4x3:
      return 4.0 / 3.0
    }
  }

  var previewAspectRatio: CGFloat {
    switch self {
    case .ratio16x9:
      return 9.0 / 16.0
    case .ratio1x1:
      return 1.0
    case .ratio4x3:
      return 3.0 / 4.0
    }
  }
}
