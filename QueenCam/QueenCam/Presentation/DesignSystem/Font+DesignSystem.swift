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

enum TypographyStyle: CaseIterable {
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
  case sfR10
  case sfR11
  case sfR13
  case sfR15
  case sfM11
  case sfM12
  case sfSB15

  var displayName: String {
    switch self {
    case .r12: return "R_12"
    case .m10: return "M_10"
    case .m13: return "M_13"
    case .m14: return "M_14"
    case .m15: return "M_15"
    case .m18: return "M_18"
    case .m22: return "M_22"
    case .sb12: return "SB_12"
    case .sb15: return "SB_15"
    case .sb16: return "SB_16"
    case .sb17: return "SB_17"
    case .sb20: return "SB_20"
    case .b22: return "B_22"
    case .sfRoundedR15: return "SF_Rounded_R_15"
    case .sfR10: return "SF R_10"
    case .sfR11: return "SF R_11"
    case .sfR13: return "SF R_13"
    case .sfR15: return "SF R_15"
    case .sfM11: return "SF M_11"
    case .sfM12: return "SF M_12"
    case .sfSB15: return "SF SB_15"
    }
  }

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
    case .sfR10: return .system(size: 10, weight: .regular)
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
    case .sfR10: return .systemFont(ofSize: 10, weight: .regular)
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
    case .sfR10: return 12
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
  struct TypographyDemoPreviewContainer: View {
    @ViewBuilder func demoTypoView(style: TypographyStyle) -> some View {
      Text("타이포그라피 - \(style.displayName)")
        .typo(style)
        .border(.gray, width: 0.5)

      Text("여왕처럼 생각하세요. 여왕은 실패를 두려워하지 않습니다. 실패는 위대함을 향한 또 하나의 디딤돌이니까요. - 오프라 윈프리")
        .typo(style)
        .border(.gray, width: 0.5)

      Text("Think like a queen. A queen is not afraid to fail. Failure is another steppingstone to greatness. - Oprah Winfrey")
        .typo(style)
        .border(.gray, width: 0.5)

      Divider()
    }

    var body: some View {
      ScrollView {
        VStack(spacing: 12) {
          ForEach(TypographyStyle.allCases, id: \.self) { style in
            demoTypoView(style: style)
          }
        }
        .padding()
      }
    }
  }

  return TypographyDemoPreviewContainer()
}
