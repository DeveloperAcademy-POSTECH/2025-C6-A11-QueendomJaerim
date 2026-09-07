import SwiftUI

/// 릴리즈 노트 화면에 표시할 콘텐츠
///
/// 화면 구성은 고정하고 문구와 영상만 교체해 릴리즈마다 재사용한다.
struct ReleaseNote {
  /// 이 안내를 처음 노출할 앱 버전
  let version: String
  let badge: LocalizedStringKey
  let titleLines: [TitleLine]
  let subtitle: LocalizedStringKey
  /// 번들에 들어 있는 안내 영상 파일 이름 (확장자 제외)
  let videoFileName: String
  let actionTitle: LocalizedStringKey

  var videoFileURL: URL? {
    Bundle.main.url(forResource: videoFileName, withExtension: Self.videoFileExtension)
  }

  private static let videoFileExtension = "mp4"
}

extension ReleaseNote: Identifiable {
  var id: String { version }
}

extension ReleaseNote {
  struct TitleLine {
    let text: LocalizedStringKey
    let isHighlighted: Bool

    init(_ text: LocalizedStringKey, isHighlighted: Bool = false) {
      self.text = text
      self.isHighlighted = isHighlighted
    }
  }
}

extension ReleaseNote {
  /// 이번 릴리즈에 노출할 안내
  ///
  /// 새 릴리즈에서는 이 정의를 통째로 교체한다.
  static let current = ReleaseNote(
    version: "1.1.11",
    badge: "NEW",
    titleLines: [
      TitleLine("우리가 그린 그림을"),
      TitleLine("사진과 함께 저장할 수 있어요!", isHighlighted: true)
    ],
    subtitle: "‘사진에 펜 가이드 함께 저장’ 기능을 설정해보세요.",
    videoFileName: "release_note_guide_0",
    actionTitle: "사용해보기"
  )
}
