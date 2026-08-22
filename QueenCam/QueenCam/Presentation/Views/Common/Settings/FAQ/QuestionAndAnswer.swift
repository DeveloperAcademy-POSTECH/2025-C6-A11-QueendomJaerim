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
      question: "촬영한 사진이 서버에 저장되나요?",
      answer: """
        촬영한 사진은 사용자의 기기에만 저장됩니다.
        앱에서 별도 저장, 보관하지 않으니 안심하고 이용해 주세요!
        """
    ),
    QuestionAndAnswer(
      id: 1,
      question: "찍자를 사용할 수 있는 기기 사양이 궁금해요.",
      answer: """
        찍자는 iPhone 12 이상, iOS 26 이상에서 사용할 수 있어요. 찍자는 두 기기를 연결하기 위해 WiFi Aware 기술을 사용합니다. 해당 기능을 지원하는 iPhone에서만 이용할 수 있습니다.
        현재 Android는 지원하지 않습니다. 더 나은 찍자를 만들기 위해 지금은 iOS 환경을 먼저 안정화하고 있어요.
        
        [지원 기기]
        - iPhone 12 및 이후 모델
        - iOS 26 이상
        """
    ),
    QuestionAndAnswer(
      id: 2,
      question: "기기 검색(페어링)이 잘 안 돼요.",
      answer: """
        우선 연결하려는 기기들의 역할이 다른지 확인해 주세요. 한 명은 모델을, 다른 한 명은 촬영을 선택해야 합니다.
        
        만약 이후에도 연결이 되지 않는다면 두 기기 모두 전원을 껐다 켜서 재시도 해보시길 권장드립니다.
        """
    ),
    QuestionAndAnswer(
      id: 3,
      question: "다른 기기와 연결이 잘 안돼요.",
      answer: """
        두 기기 모두 아래 경로에서 WiFi 식별자를 재설정해주세요. 재설정 후 다시 기기 검색을 시도해주세요.
        [ 설정 〉 개인정보보호 및 보안 〉 페어링된 기기 〉 WiFi 식별자 재설정 ]
        """
    ),
    QuestionAndAnswer(
      id: 4,
      question: "매번 기기 검색 후, 연결을 해야하는지 궁금해요.",
      answer: "이전에 기기 검색을 통해 페어링하여 등록된 친구 리스트에 있는 기기와는 ‘연결’ 버튼만 눌러 바로 연결할 수 있어요."
    ),
    QuestionAndAnswer(
      id: 5,
      question: "등록된 기기를 삭제하고 싶어요.",
      answer: """
        아래 경로에서 등록된 기기를 삭제할 수 있어요.
        [ 설정 〉 개인정보 보호 및 보안 〉 페어링된 기기 〉 삭제 ]
        """
    ),
    QuestionAndAnswer(
      id: 6,
      question: "이전에 연결했던 기기가 등록된 친구에서 보이지 않아요.",
      answer: "iOS 시스템 이슈로 인해 이전에 페어링했던 기기의 정보가 사라지는 문제가 발생할 수 있습니다. 번거로우시겠지만 다시 한번 친구와 기기 등록을 진행해주세요."
    ),
    QuestionAndAnswer(
      id: 7,
      question: "페어링을 진행할 때, 상대 기기에 나온 코드를 입력했지만 그 화면에서 넘어가지 않아요.",
      answer: """
        iOS 시스템 이슈로 인해 페어링이 원활하게 완료되지 않는 문제가 발생할 수 있습니다. 번거로우시겠지만 취소를 눌러 코드를 다시 입력해주세요.

        만약 이후에도 문제가 발생한다면 두 기기 모두 전원을 껐다 켜서 재시도 해보시길 권장드립니다.
        """
    ),
    QuestionAndAnswer(
      id: 8,
      question: "찍자 사용할 때, 주변 와이파이에 연결하거나 데이터를 켜두어야 하나요?",
      answer:
        "아니요! 찍자는 별도의 네트워크 연결이 필요하지 않습니다. 다만, 두 기기의 빠르고 매끄러운 연결을 위해 Wi-Fi Aware 기술을 사용하고 있기 때문에 와이파이가(와이파이 버튼이) 활성화 되어있기만 하면 됩니다."
    ),
    QuestionAndAnswer(
      id: 9,
      question: "찍자를 사용하다가 발생하는 문제나 오류는 어디로 신고를 하면 되나요?",
      answer: """
        찍자 앱 설정 〉 의견 보내기에서 바로 알려주세요! 또는 아래 채널로도 문의할 수 있어요.
        - Instagram DM: @zzikzza.kr
        - 이메일: zzikzza@gmail.com
        """
    )
  ]
  // swiftlint:enable line_length trailing_whitespace
}
