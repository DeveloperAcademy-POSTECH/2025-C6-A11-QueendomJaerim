//
//  WifiAwareGuide.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import SwiftUI

struct WifiAwareGuide {
  let type: GuideType
  let message: AttributedContents
  let video: GuideVideo

  static let photographerGuides: [Self] = [
    .init(
      type: .photographer,
      message: AttributedContents(nodes: [
        .text(text: String(localized: "'주변 기기 찾기'"), style: .highlighted),
        .text(text: String(localized: "를 시작하고\n잠시 기다려주세요."), style: .normal)
      ]),
      video: .photographerGuide0
    ),
    .init(
      type: .photographer,
      message: AttributedContents(nodes: [
        .text(text: String(localized: "6자리 코드가 나오면\n친구에게 "), style: .normal),
        .text(text: String(localized: "코드를 알려주세요."), style: .highlighted)
      ]),
      video: .photographerGuide1
    ),
    .init(
      type: .photographer,
      message: AttributedContents(nodes: [
        .text(text: String(localized: "이 화면이 뜨면 등록 완료에요.\n"), style: .normal),
        .text(text: String(localized: "창을 닫으면"), style: .highlighted),
        .text(text: String(localized: " 연결 준비 완료!"), style: .normal)
      ]),
      video: .photographerGuide2
    ),
    .init(
      type: .photographer,
      message: AttributedContents(nodes: [
        .text(text: String(localized: "언제든지 "), style: .normal),
        .inlineImage(type: .systemImage(systemName: "questionmark.circle"), style: .normal),
        .text(text: String(localized: " 버튼으로\n페어링하는 법을 다시 볼 수 있어요."), style: .normal)
      ]),
      video: .photographerGuide3
    )
  ]

  static let modelGuides: [Self] = [
    .init(
      type: .model,
      message: AttributedContents(nodes: [
        .text(text: String(localized: "'주변 기기 찾기'"), style: .highlighted),
        .text(text: String(localized: "를 시작해\n친구에게 "), style: .normal),
        .text(text: String(localized: "페어링을 요청"), style: .highlighted),
        .text(text: String(localized: "해주세요."), style: .normal)
      ]),
      video: .modelGuide0
    ),
    .init(
      type: .model,
      message: AttributedContents(nodes: [
        .text(text: String(localized: "친구가 알려주는\n6자리 "), style: .normal),
        .text(text: String(localized: "코드를 입력"), style: .highlighted),
        .text(text: String(localized: "해주세요."), style: .normal)
      ]),
      video: .modelGuide1
    ),
    .init(
      type: .model,
      message: AttributedContents(nodes: [
        .text(text: String(localized: "이 화면이 뜨면 등록 완료에요.\n"), style: .normal),
        .text(text: String(localized: "창을 닫으면"), style: .highlighted),
        .text(text: String(localized: " 연결 준비 완료!"), style: .normal)
      ]),
      video: .modelGuide2
    ),
    .init(
      type: .model,
      message: AttributedContents(nodes: [
        .text(text: String(localized: "언제든지 "), style: .normal),
        .inlineImage(type: .systemImage(systemName: "questionmark.circle"), style: .normal),
        .text(text: String(localized: " 버튼으로\n페어링하는 법을 다시 볼 수 있어요."), style: .normal)
      ]),
      video: .modelGuide3
    )
  ]
  
  enum GuideType {
    case photographer
    case model
  }
}
