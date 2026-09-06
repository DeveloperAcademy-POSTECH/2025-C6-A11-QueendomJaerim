import Foundation

enum ReleaseNoteVideo {
  case penGuideOverlay

  private var videoFileExtension: String { "mp4" }

  private var videoFileName: String {
    switch self {
    case .penGuideOverlay: return "release_note_guide_0"
    }
  }

  var videoFileURL: URL? {
    Bundle.main.url(forResource: videoFileName, withExtension: videoFileExtension)
  }
}
