import SwiftUI

/// 릴리즈 노트 화면에 표시할 콘텐츠
///
/// 화면 구성은 고정하고 문구와 영상만 교체해 릴리즈마다 재사용한다.
struct ReleaseNote {
  let badge: LocalizedStringKey
  let titleLines: [TitleLine]
  let subtitle: LocalizedStringKey
  let video: ReleaseNoteVideo
  let actionTitle: LocalizedStringKey
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
  static let penGuideOverlay = ReleaseNote(
    badge: "NEW",
    titleLines: [
      TitleLine("우리가 그린 그림을"),
      TitleLine("사진과 함께 저장할 수 있어요!", isHighlighted: true)
    ],
    subtitle: "‘사진에 펜 가이드 함께 저장’ 기능을 설정해보세요.",
    video: .penGuideOverlay,
    actionTitle: "사용해보기"
  )
}
