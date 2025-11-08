import SwiftUI

extension Font {
  enum PretendardWeight {
    case regular
    case medium
    case semibold
    case bold

    var fontName: String {
      switch self {
      case .regular: return "Pretendard-Regular"
      case .medium: return "Pretendard-Medium"
      case .semibold: return "Pretendard-Semibold"
      case .bold: return "Pretendard-Bold"
      }
    }
  }

  static func pretendard(_ weight: PretendardWeight, size: CGFloat) -> Font {
    .custom(weight.fontName, size: size)
  }
}

extension UIFont {
  enum PretendardWeight {
    case regular
    case medium
    case semibold
    case bold

    var fontName: String {
      switch self {
      case .regular: return "Pretendard-Regular"
      case .medium: return "Pretendard-Medium"
      case .semibold: return "Pretendard-Semibold"
      case .bold: return "Pretendard-Bold"
      }
    }
  }

  static func pretendard(_ weight: PretendardWeight, size: CGFloat) -> UIFont {
    UIFont(name: weight.fontName, size: size)!
  }
}

extension UIFont {
  /// Rounded 폰트
  /// ref: https://stackoverflow.com/a/63247870
  class func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
    let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
    let font: UIFont

    if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
      font = UIFont(descriptor: descriptor, size: size)
    } else {
      font = systemFont
    }
    return font
  }
}

enum TypographyStyle {
  case r12
  case m10
  case m13
  case m14
  case m15
  case m18
  case m22
  case sb12
  case sb15
  case sb16
  case sb17
  case sb20
  case b22
  case sfRoundedR15
  case sfR11
  case sfR13
  case sfR15
  case sfM11
  case sfM12
  case sfSB15

  var font: Font {
    switch self {
    case .r12: return .pretendard(.regular, size: 12)
    case .m10: return .pretendard(.medium, size: 10)
    case .m13: return .pretendard(.medium, size: 13)
    case .m14: return .pretendard(.medium, size: 14)
    case .m15: return .pretendard(.medium, size: 15)
    case .m18: return .pretendard(.medium, size: 18)
    case .m22: return .pretendard(.medium, size: 22)
    case .sb12: return .pretendard(.medium, size: 12)
    case .sb15: return .pretendard(.medium, size: 15)
    case .sb16: return .pretendard(.medium, size: 16)
    case .sb17: return .pretendard(.medium, size: 17)
    case .sb20: return .pretendard(.medium, size: 20)
    case .b22: return .pretendard(.bold, size: 22)
    case .sfRoundedR15: return .system(size: 15, weight: .regular, design: .rounded)
    case .sfR11: return .system(size: 11, weight: .regular)
    case .sfR13: return .system(size: 13, weight: .regular)
    case .sfR15: return .system(size: 15, weight: .regular)
    case .sfM11: return .system(size: 11, weight: .medium)
    case .sfM12: return .system(size: 12, weight: .medium)
    case .sfSB15: return .system(size: 15, weight: .semibold)
    }
  }

  var uiFont: UIFont {
    switch self {
    case .r12: return .pretendard(.regular, size: 12)
    case .m10: return .pretendard(.medium, size: 10)
    case .m13: return .pretendard(.medium, size: 13)
    case .m14: return .pretendard(.medium, size: 14)
    case .m15: return .pretendard(.medium, size: 15)
    case .m18: return .pretendard(.medium, size: 18)
    case .m22: return .pretendard(.medium, size: 22)
    case .sb12: return .pretendard(.medium, size: 12)
    case .sb15: return .pretendard(.medium, size: 15)
    case .sb16: return .pretendard(.medium, size: 16)
    case .sb17: return .pretendard(.medium, size: 17)
    case .sb20: return .pretendard(.medium, size: 20)
    case .b22: return .pretendard(.bold, size: 22)
    case .sfRoundedR15: return .rounded(ofSize: 15, weight: .regular)
    case .sfR11: return .systemFont(ofSize: 11, weight: .regular)
    case .sfR13: return .systemFont(ofSize: 13, weight: .regular)
    case .sfR15: return .systemFont(ofSize: 15, weight: .regular)
    case .sfM11: return .systemFont(ofSize: 11, weight: .medium)
    case .sfM12: return .systemFont(ofSize: 12, weight: .medium)
    case .sfSB15: return .systemFont(ofSize: 15, weight: .semibold)
    }
  }

  var lineHeight: CGFloat {
    switch self {
    case .r12: return 16
    case .m10: return 12
    case .m13: return 16
    case .m14: return 21
    case .m15: return 23
    case .m18: return 27
    case .m22: return 33
    case .sb12: return 18
    case .sb15: return 22
    case .sb16: return 24
    case .sb17: return 20
    case .sb20: return 30
    case .b22: return 33
    case .sfRoundedR15: return 18
    case .sfR11: return 13
    case .sfR13: return 16
    case .sfR15: return 23
    case .sfM11: return 13
    case .sfM12: return 14
    case .sfSB15: return 18
    }
  }

  var letterSpacing: CGFloat {
    switch self {
    case .sfRoundedR15: return -0.4  // Figma 상 0인데 차이가 나서 매뉴얼하게 조정
    case .sfSB15: return -0.05  // Figma 상 -0.2인데 차이가 나서 매뉴얼하게 조정 (네 배 차이)
    default: return 0
    }
  }
}

/// ref: https://stackoverflow.com/a/64652348
struct TypographyModifier: ViewModifier {
  let style: TypographyStyle

  func body(content: Content) -> some View {
    content
      .font(Font(style.uiFont))
      .kerning(style.letterSpacing)
      .lineSpacing(style.lineHeight - style.uiFont.lineHeight)
      .padding(.vertical, (style.lineHeight - style.uiFont.lineHeight) / 2)
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
      
      // === 여러 줄 ===
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
      
      Text("m15: Pretendard Medium 15\n여러 줄 테스트")
        .typo(.m15)
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
      
      Text("sfR15: SF Pro Regular 15\n여러 줄 테스트")
        .typo(.sfR15)
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
      
      Divider()
      
      // === 한 줄 ===
      // --- Pretendard ---
      Text("r12: Pretendard Regular 12 한 줄 테스트")
        .typo(.r12)
        .border(.gray, width: 0.5)

      Text("m10: Pretendard Medium 10 한 줄 테스트")
        .typo(.m10)
        .border(.gray, width: 0.5)

      Text("m13: Pretendard Medium 13 한 줄 테스트")
        .typo(.m13)
        .border(.gray, width: 0.5)
      
      Text("m15: Pretendard Medium 15 한 줄 테스트")
        .typo(.m15)
        .border(.gray, width: 0.5)

      // --- SF Pro Rounded ---
      Text("sfRoundedR15: SF Rounded Regular 15 한 줄 테스트")
        .typo(.sfRoundedR15)
        .border(.gray, width: 0.5)

      // --- SF Pro ---
      Text("sfR11: SF Pro Regular 11 한 줄 테스트")
        .typo(.sfR11)
        .border(.gray, width: 0.5)

      Text("sfR13: SF Pro Regular 13 한 줄 테스트")
        .typo(.sfR13)
        .border(.gray, width: 0.5)
      
      Text("sfR15: SF Pro Regular 15 한 줄 테스트")
        .typo(.sfR15)
        .border(.gray, width: 0.5)

      Text("sfM11: SF Pro Medium 11 한 줄 테스트")
        .typo(.sfM11)
        .border(.gray, width: 0.5)

      Text("sfM12: SF Pro Medium 12 한 줄 테스트")
        .typo(.sfM12)
        .border(.gray, width: 0.5)

      Text("sfSB15: SF Pro Semibold 15 (자간 -0.2 적용됨)")
        .typo(.sfSB15)
        .border(.gray, width: 0.5)
    }
    .padding()
  }
}
