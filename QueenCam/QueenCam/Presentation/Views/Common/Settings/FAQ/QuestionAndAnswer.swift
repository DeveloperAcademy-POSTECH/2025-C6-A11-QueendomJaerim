//
//  QuestionAndAnswer.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import SwiftUI

struct QuestionAndAnswer: Identifiable {
  let id: Int
  let question: LocalizedStringKey
  let answer: LocalizedStringKey

  // swiftlint:disable line_length trailing_whitespace
  static let faqList: [QuestionAndAnswer] = [
    QuestionAndAnswer(
      id: 0,
      question: "찍자를 사용할 수 있는 기기 사양이 궁금해요.",
      answer: """
        찍자에 적용된 최신 기술을 구동하기 위해서는 아이폰 12 이상의 모델이 필요합니다. 또한, 소프트웨어 버전도 중요해요. 원활한 실행을 위해 iOS 26 이상으로 업데이트가 되어 있어야만 사용하실 수 있습니다.
        
        찍자는 두 기기의 빠르고 매끄러운 연결을 위해 Wi-Fi Aware 기술을 사용하고 있습니다. 이 기술은 기기 자체에 내장된 하드웨어(부품)가 있어야만 작동해요. 아쉽게도 해당 부품이 없는 이전 모델은 소프트웨어 업데이트만으로는 지원이 어려운 점, 너른 양해 부탁드립니다.
        
        또한, 현재 찍자는 안드로이드에서 다운로드가 되지 않습니다. 안드로이드 유저분들의 요청이 많다는 것을 잘 알고 있습니다. 하지만 지금은 더 완벽한 서비스를 만들기 위해 iOS 환경 안정화에 전념하고 있어요.
        
        [찍자 지원 기기]
        iPhone 12 및 그 이후에 출시된 iPhone
        """
    ),
    QuestionAndAnswer(
      id: 1,
      question: "기기 검색(페어링)이 잘 안 돼요.",
      answer: """
        우선 연결하려는 기기들의 역할이 다른지 확인해 주세요. 한 명은 모델을, 다른 한 명은 작가를 선택해야 합니다.
        
        만약 이후에도 연결이 되지 않는다면 두 기기 모두 전원을 껐다 켜서 재시도 해보시길 권장드립니다.
        """
    ),
    QuestionAndAnswer(
      id: 2,
      question: "다른 기기와 연결이 잘 안 안돼요.",
      answer: """
        아래 경로를 통해 ‘Wi-Fi 식별자 재설정’을 진행하면 문제가 해결될 수도 있습니다.
        
        [아이폰 ‘설정’→개인정보 보호 및 보안→페어링된 기기→Wi-Fi 식별자 재설정]
        
        연결하려는 두 기기 모두 재설정해주시는 것이 가장 정확합니다.
        """
    ),
    QuestionAndAnswer(
      id: 3,
      question: "매번 기기 검색 후, 연결을 해야하는지 궁금해요.",
      answer: "이전에 기기 검색을 통해 페어링하여 등록된 친구 리스트에 있는 기기와는 ‘연결’ 버튼만 눌러 바로 연결할 수 있어요."
    ),
    QuestionAndAnswer(
      id: 4,
      question: "등록된 기기를 지우고 싶어요.",
      answer: """
        아래 경로를 통해 등록된 기기를 삭제할 수 있습니다.
        
        [아이폰 ‘설정’→개인정보 보호 및 보안→페어링된 기기→편집→삭제]
        """
    ),
    QuestionAndAnswer(
      id: 5,
      question: "이전에 연결했던 기기가 등록된 친구에서 보이지 않아요.",
      answer: "애플 시스템 오류로 이런 일이 가끔 발생합니다. 번거로우시겠지만 다시 한번 친구와 기기 등록을 진행해 주세요."
    ),
    QuestionAndAnswer(
      id: 6,
      question: "페어링 진행할 때, 상대 기기에 나온 번호를 입력했지만 그 화면에서 넘어가지 않아요.",
      answer: """
        애플 시스템 오류로 이런 일이 가끔 발생합니다. 번거로우시겠지만 취소를 눌러 번호입력을 재시도해주세요.
        
        만약 이후에도 문제가 발생한다면 두 기기 모두 전원을 껐다 켜서 재시도 해보시길 권장드립니다.
        """
    ),
    QuestionAndAnswer(
      id: 7,
      question: "찍자 사용할 때, 주변 와이파이에 연결하거나 데이터를 켜두어야 하나요?",
      answer:
        "아니요! 찍자는 별도의 네트워크 연결이 필요하지 않습니다. 다만, 두 기기의 빠르고 매끄러운 연결을 위해 Wi-Fi Aware 기술을 사용하고 있기 때문에 와이파이가(와이파이 버튼이) 활성화 되어있기만 하면 됩니다."
    ),
    QuestionAndAnswer(
      id: 8,
      question: "찍자를 사용하다가 발생하는 문제나 오류는 어디로 신고를 하면 되나요?",
      answer: """
        찍자 앱의 설정 페이지에 있는 ‘의견 보내기’를 활용할 수 있습니다.
        
        또한 찍자 인스타그램 DM([@zzikzza.kr](https://www.instagram.com/zzikzza.kr)) 또는 이메일 ([zzikzza@gmail.com](mailto:zzikzza@gmail.com))로 문의가 가능해요.
        """
    )
  ]
  // swiftlint:enable line_length trailing_whitespace
}
