import SwiftUI

extension Font {
  enum PretendardWeight {
    case regular
    case medium

    var fontName: String {
      switch self {
      case .regular: return "Pretendard-Regular"
      case .medium: return "Pretendard-Medium"
      }
    }
  }

  static func pretendard(_ weight: PretendardWeight, size: CGFloat) -> Font {
    .custom(weight.fontName, size: size)
  }
}

enum TypographyStyle {
  case r12
  case m10
  case m13
  case sfRoundedR15
  case sfR11
  case sfR13
  case sfM11
  case sfM12
  case sfSB15

  var font: Font {
    switch self {
    case .r12: return .pretendard(.regular, size: 12)
    case .m10: return .pretendard(.medium, size: 10)
    case .m13: return .pretendard(.medium, size: 13)
    case .sfRoundedR15: return .system(size: 15, weight: .regular, design: .rounded)
    case .sfR11: return .system(size: 11, weight: .regular)
    case .sfR13: return .system(size: 13, weight: .regular)
    case .sfM11: return .system(size: 11, weight: .medium)
    case .sfM12: return .system(size: 12, weight: .medium)
    case .sfSB15: return .system(size: 15, weight: .semibold)
    }
  }

  var lineSpacing: CGFloat {
    switch self {
    case .r12: return 4
    case .m10: return 2
    case .m13: return 3
    case .sfRoundedR15: return 3
    case .sfR11: return 2
    case .sfR13: return 3
    case .sfM11: return 2
    case .sfM12: return 2
    case .sfSB15: return 3
    }
  }

  var letterSpacing: CGFloat {
    switch self {
    case .sfSB15: return -0.2
    default: return 0
    }
  }
}

struct TypographyModifier: ViewModifier {
  let style: TypographyStyle

  func body(content: Content) -> some View {
    content
      .font(style.font)
      .kerning(style.letterSpacing)
      .lineSpacing(style.lineSpacing)
      .padding(.vertical, style.lineSpacing / 2)
  }
}

extension View {
  func typo(_ style: TypographyStyle) -> some View {
    self.modifier(TypographyModifier(style: style))
  }
}

// --- 사용 예시 ---
#Preview {
  ScrollView {
    VStack(spacing: 12) {

      // --- Pretendard ---
      Text("r12: Pretendard Regular 12\n여러 줄 테스트")
        .typo(.r12)
        .border(.gray, width: 0.5)

      Text("m10: Pretendard Medium 10\n여러 줄 테스트")
        .typo(.m10)
        .border(.gray, width: 0.5)

      Text("m13: Pretendard Medium 13\n여러 줄 테스트")
        .typo(.m13)
        .border(.gray, width: 0.5)

      // --- SF Pro Rounded ---
      Text("sfRoundedR15: SF Rounded Regular 15\n여러 줄 테스트")
        .typo(.sfRoundedR15)
        .border(.gray, width: 0.5)

      // --- SF Pro ---
      Text("sfR11: SF Pro Regular 11\n여러 줄 테스트")
        .typo(.sfR11)
        .border(.gray, width: 0.5)

      Text("sfR13: SF Pro Regular 13\n여러 줄 테스트")
        .typo(.sfR13)
        .border(.gray, width: 0.5)

      Text("sfM11: SF Pro Medium 11\n여러 줄 테스트")
        .typo(.sfM11)
        .border(.gray, width: 0.5)

      Text("sfM12: SF Pro Medium 12\n여러 줄 테스트")
        .typo(.sfM12)
        .border(.gray, width: 0.5)

      Text("sfSB15: SF Pro Semibold 15\n(자간 -0.2 적용됨)")
        .typo(.sfSB15)
        .border(.gray, width: 0.5)
    }
    .padding()
  }
}
