//
//  QuestionView.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import SwiftUI

struct QuestionView {
  let question: LocalizedStringKey

  var isClosed: Bool = true
  var chevronName: String { isClosed ? "chevron.down" : "chevron.up" }

  // MARK: - Spacings
  let topSpacing: CGFloat = 18
  let bottomSpacing: CGFloat = 18
  let horizontalSpacing: CGFloat = 20
}

extension QuestionView: View {
  var body: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 0) {
        Image(.question)

        Spacer()
          .frame(width: 11)

        Text(question)
          .typo(.r15)
          .foregroundStyle(.systemWhite)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)

        Image(systemName: chevronName)
          .font(.system(size: 10, weight: .semibold))
          .lineSpacing(3.3)
          .foregroundStyle(.gray500)
          .padding(.top, 5.5)
          .padding(.bottom, 3.3)
          .padding(.leading, 24)
          .padding(.trailing, 6)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, topSpacing)
      .padding(.bottom, bottomSpacing)
      
      if isClosed {
        Rectangle()
          .frame(height: 1)
          .foregroundStyle(.gray950)
      }
    }
    .padding(.horizontal, horizontalSpacing)
  }
}

extension QuestionView {
  func close(_ isClosed: Bool) -> Self {
    var body = self
    body.isClosed = isClosed
    return body
  }
}

#Preview {
  VStack(spacing: 0) {
    QuestionView(
      question: "기기 검색이 잘 안 돼요."
    )

    QuestionView(
      question: "찍자를 사용할 수 있는 기기 사양이 궁금해요. 내꺼는 돼나? 궁금궁금..."
    )
    .close(false)
  }
}
