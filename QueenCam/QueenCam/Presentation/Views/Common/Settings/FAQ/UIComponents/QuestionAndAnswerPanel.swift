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
    Button {
      withAnimation {
        isExpanded.toggle()
      }
    } label: {
      VStack(spacing: 0) {
        QuestionView(question: questionAndAnser.question, isClosed: !isExpanded)
        if isExpanded {
          AnswerView(answer: questionAndAnser.answer)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
    }
  }
}

#Preview {
  QuestionAndAnswerPanel(questionAndAnser: QuestionAndAnswer.faqList.first!)
}
