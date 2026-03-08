//
//  QuestionAndAnswerPanel.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import SwiftUI

struct QuestionAndAnswerPanel {
  let questionAndAnser: QuestionAndAnswer
  @State var isExpanded: Bool = false
}

extension QuestionAndAnswerPanel: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Button {
        withAnimation {
          isExpanded.toggle()
        }
      } label: {
        QuestionView(question: questionAndAnser.question, isClosed: !isExpanded)
      }

      if isExpanded {
        AnswerView(answer: questionAndAnser.answer)
      }
    }
    .clipped()
  }
}

#Preview {
  QuestionAndAnswerPanel(questionAndAnser: QuestionAndAnswer.faqList.first!)
}
