//
//  WifiAwareGuide.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import SwiftUI

struct WifiAwareGuide {
  let message: AttributedString
  let video: GuideVideo

  static let photographerGuides: [Self] = [
    .init(
      message: highlighted(
        original: AttributedString("‘주변 기기 찾기’를 시작하고\n잠시 기다려주세요."),
        target: "‘주변 기기 찾기’",
        color: .photographerPrimary
      ),
      video: .photographerGuide0
    ),
    .init(
      message: highlighted(
        original: AttributedString("6자리 코드가 나오면\n친구에게 코드를 알려주세요."),
        target: "코드를 알려주세요.",
        color: .photographerPrimary
      ),
      video: .photographerGuide1
    ),
    .init(
      message: highlighted(
        original: AttributedString("이 화면이 뜨면 등록 완료에요.\n창을 닫으면 연결 준비 완료!"),
        target: "창을 닫으면",
        color: .photographerPrimary
      ),
      video: .photographerGuide2
    )
  ]

  static let modelGuides: [Self] = [
    .init(
      message: highlighted(
        original: highlighted(
          original: AttributedString("‘주변 기기 찾기’를 시작해\n친구에게 페어링을 요청해주세요."),
          target: "‘주변 기기 찾기’",
          color: .modelPrimary
        ),
        target: "페어링을 요청",
        color: .modelPrimary
      ),
      video: .modelGuide0
    ),
    .init(
      message: highlighted(original: AttributedString("친구가 알려주는\n6자리 코드를 입력해주세요."), target: "코드를 입력", color: .modelPrimary),
      video: .modelGuide1
    ),
    .init(
      message: highlighted(
        original: AttributedString("이 화면이 뜨면 등록 완료에요.\n창을 닫으면 연결 준비 완료!"),
        target: "창을 닫으면",
        color: .modelPrimary
      ),
      video: .modelGuide2
    )
  ]
}

extension WifiAwareGuide {
  private static func highlighted(original: AttributedString, target: any StringProtocol, color: Color) -> AttributedString {
    var copy = original

    if let highlightedRange = original.range(of: target) {
      copy[highlightedRange].foregroundColor = color
      copy[highlightedRange].font = .pretendard(.bold, size: 22)
    }

    return copy
  }
}
