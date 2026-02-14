//
//  AnswerView.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import SwiftUI

struct AnswerView {
  let answer: LocalizedStringKey

  // MARK: - Spacings
  let topSpacing: CGFloat = 22
  let bottomSpacing: CGFloat = 28
  let horizontalSpacing: CGFloat = 20
}

extension AnswerView: View {
  var body: some View {
    HStack(alignment: .top, spacing: 11) {
      Image(.answer)

      Text(answer)
        .typo(.r15)
        .foregroundStyle(.systemWhite)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, topSpacing)
    .padding(.bottom, bottomSpacing)
    .padding(.horizontal, horizontalSpacing)
    .background(.gray950)
  }
}

#Preview {
  VStack(spacing: 0) {
    AnswerView(
      // swiftlint:disable trailing_whitespace
      answer: """
        연결이 원활하지 않다면 설정을 초기화해 보세요.

        아래 경로를 통해 ‘Wi-Fi 식별자 재설정’을 진행하면 
        문제가 해결될 수 있습니다.

        ▣ 설정 → 개인정보 보호 및 보안 
        → 페어링된 기기 → Wi-Fi 식별자 재설정

        연결하려는 두 기기 모두 재설정해주시는 것이 가장 확실합니다. 
        """
      // swiftlint:enable trailing_whitespace
    )

    AnswerView(
      answer: "네.\n아마도요."
    )
  }
}
