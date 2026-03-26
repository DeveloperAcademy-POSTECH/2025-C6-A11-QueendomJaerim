//
//  FAQView.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import SwiftUI

struct FAQView {
  var faqList: [QuestionAndAnswer] {
    QuestionAndAnswer.faqList
  }
}

extension FAQView: View {
  var body: some View {
    ScrollView {
      ForEach(faqList) { faq in
        QuestionAndAnswerPanel(questionAndAnser: faq)
      }
    }
    .navigationTitle("자주하는 질문")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  FAQView()
}
