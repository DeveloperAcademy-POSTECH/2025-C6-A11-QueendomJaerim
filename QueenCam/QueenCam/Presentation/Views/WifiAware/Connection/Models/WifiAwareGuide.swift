//
//  WifiAwareGuide.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import SwiftUI

struct WifiAwareGuide {
  let message: NSAttributedString
  let video: GuideVideo

  static let photographerGuides: [Self] = [
    .init(
      message: highlighted(
        original: base(for: String(localized: "‘주변 기기 찾기’를 시작하고\n잠시 기다려주세요.")),
        target: String(localized: "‘주변 기기 찾기’"),
        color: .photographerPrimary
      ),
      video: .photographerGuide0
    ),
    .init(
      message: highlighted(
        original: base(for: String(localized: "6자리 코드가 나오면\n친구에게 코드를 알려주세요.")),
        target: String(localized: "코드를 알려주세요."),
        color: .photographerPrimary
      ),
      video: .photographerGuide1
    ),
    .init(
      message: highlighted(
        original: base(for: String(localized: "이 화면이 뜨면 등록 완료에요.\n창을 닫으면 연결 준비 완료!")),
        target: String(localized: "창을 닫으면"),
        color: .photographerPrimary
      ),
      video: .photographerGuide2
    ),
    .init(
      message: attached(
        original: base(for: String(localized: "언제든지 gearshape 버튼으로\n페어링하는 법을 다시 볼 수 있어요.")),
        target: "gearshape",
        imageName: "gearshape",
        foregroundColor: .systemWhite
      ),
      video: .photographerGuide3
    )
  ]

  static let modelGuides: [Self] = [
    .init(
      message: highlighted(
        original: highlighted(
          original: base(for: String(localized: "‘주변 기기 찾기’를 시작해\n친구에게 페어링을 요청해주세요.")),
          target: String(localized: "‘주변 기기 찾기’"),
          color: .modelPrimary
        ),
        target: String(localized: "페어링을 요청"),
        color: .modelPrimary
      ),
      video: .modelGuide0
    ),
    .init(
      message: highlighted(
        original: base(for: String(localized: "친구가 알려주는\n6자리 코드를 입력해주세요.")),
        target: String(localized: "코드를 입력"),
        color: .modelPrimary
      ),
      video: .modelGuide1
    ),
    .init(
      message: highlighted(
        original: base(for: String(localized: "이 화면이 뜨면 등록 완료에요.\n창을 닫으면 연결 준비 완료!")),
        target: String(localized: "창을 닫으면"),
        color: .modelPrimary
      ),
      video: .modelGuide2
    ),
    .init(
      message: attached(
        original: base(for: String(localized: "언제든지 gearshape 버튼으로\n페어링하는 법을 다시 볼 수 있어요.")),
        target: "gearshape",
        imageName: "gearshape",
        foregroundColor: .systemWhite
      ),
      video: .modelGuide3
    )
  ]
}

extension WifiAwareGuide {
  private static func base(
    for text: String,
    style: TypographyStyle = .m22,
    align: NSTextAlignment = .center
  ) -> NSAttributedString {
    NSAttributedString(string: text, attributes: makeBaseAttributes(style: style, align: align))
  }

  private static func highlighted(
    original: NSAttributedString,
    target: String,
    color: UIColor,
    style: TypographyStyle = .b22,
    align: NSTextAlignment = .center
  ) -> NSAttributedString {
    let highlightedRange = (original.string as NSString).range(of: target)
    guard highlightedRange.location != NSNotFound else {
      return original
    }

    let copy = NSMutableAttributedString(attributedString: original)

    var attributes = makeBaseAttributes(style: style, align: align)
    attributes[.foregroundColor] = color

    copy.setAttributes(attributes, range: highlightedRange)

    return copy
  }

  private static func attached(
    original: NSAttributedString,
    target: String,
    imageName: String,
    foregroundColor: UIColor,
    style: TypographyStyle = .m22,
    align: NSTextAlignment = .center
  ) -> NSAttributedString {
    let range = (original.string as NSString).range(of: target)
    guard range.location != NSNotFound else {
      return original
    }

    guard
      let image = UIImage(
        systemName: imageName,
        withConfiguration: UIImage.SymbolConfiguration(pointSize: style.uiFont.pointSize, weight: .medium)
      )?
        .withTintColor(foregroundColor, renderingMode: .alwaysOriginal)
    else {
      return original
    }

    let copy = NSMutableAttributedString(attributedString: original)

    let attachment = NSTextAttachment()
    attachment.image = image

    let imageString = NSAttributedString(
      attachment: attachment,
      attributes: makeBaseAttributes(style: style, align: align)
    )
    copy.replaceCharacters(in: range, with: imageString)

    return copy
  }

  private static func makeBaseAttributes(style: TypographyStyle, align: NSTextAlignment) -> [NSAttributedString.Key: Any] {
    let uiFont = style.uiFont
    let lineHeight = style.lineHeight
    let letterSpacing = style.letterSpacing

    // 1. Paragraph Style
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.minimumLineHeight = lineHeight
    paragraphStyle.maximumLineHeight = lineHeight
    paragraphStyle.alignment = align

    // 2. 수직 중앙 정렬을 위한 Baseline Offset
    // (전체 줄 높이 - 폰트 자체의 높이) / 2 만큼 텍스트를 위로 올림
    let baselineOffset = (lineHeight - uiFont.lineHeight) / 2

    return [
      .font: uiFont,
      .kern: letterSpacing,
      .paragraphStyle: paragraphStyle,
      .baselineOffset: baselineOffset
    ]
  }
}
