//
//  AttributedContentsView.swift
//  QueenCam
//
//  Created by 임영택 on 1/27/26.
//

import SwiftUI

struct AttributedContentsView: View {
  let attributedContents: AttributedContents
  let textStyleProvider: (TextStyle) -> TextStyleSpecs

  var body: some View {
    build(from: attributedContents)
  }
}

#Preview {
  AttributedContentsView(
    attributedContents: AttributedContents(nodes: [
      .text(text: "안녕 ", style: .normal),
      .inlineImage(type: .systemImage(systemName: "globe"), style: .normal),
      .text(text: " 세상아", style: .highlighted)
    ])
  ) { style in
    let typo1 = TypographyStyle.m22
    let typo2 = TypographyStyle.b22

    switch style {
    case .normal:
      return .init(font: typo1.font, foregroundColor: .white)
    case .highlighted:
      return .init(font: typo2.font, foregroundColor: .blue)
    }
  }
}
