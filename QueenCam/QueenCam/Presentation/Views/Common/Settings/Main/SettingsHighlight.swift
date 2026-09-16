import Foundation

/// 설정 화면에 진입할 때 강조할 항목
///
/// 릴리즈 노트처럼 특정 설정을 안내하며 진입한 경우에만 지정한다.
enum SettingsHighlight: Hashable {
  case saveGuidingOverlayImage
}
