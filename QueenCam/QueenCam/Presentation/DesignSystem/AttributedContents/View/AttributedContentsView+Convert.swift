//
//  AttributedContentsView+Convert.swift
//  QueenCam
//
//  Created by 임영택 on 1/27/26.
//

import SwiftUI

extension AttributedContentsView {
  func build(from attributedContents: AttributedContents) -> Text {
    var key = LocalizedStringKey.StringInterpolation(literalCapacity: 0, interpolationCount: attributedContents.nodes.count)

    // 수동으로 보간
    attributedContents.nodes.forEach { node in
      switch node {
      case let .inlineImage(type, style):
        key.appendInterpolation(createImageTextNode(type: type, style: style))
      case let .text(text, style):
        key.appendInterpolation(createTextNode(content: text, style: style))
      }
    }

    return Text(LocalizedStringKey(stringInterpolation: key))
  }

  private func createImageTextNode(type: ImageType, style: TextStyle) -> Text {
    let nestedImage: Image

    switch type {
    case let .assetImage(assetName):
      nestedImage = Image(assetName)
    case let .systemImage(systemName: systemName):
      nestedImage = Image(systemName: systemName)
    }

    let textStyleSpecs = textStyleProvider(style)
    return Text(nestedImage)
      .font(textStyleSpecs.font)
      .foregroundStyle(textStyleSpecs.foregroundColor)
  }

  private func createTextNode(content: String, style: TextStyle) -> Text {
    let textStyleSpecs = textStyleProvider(style)
    return Text(content)
      .font(textStyleSpecs.font)
      .foregroundStyle(textStyleSpecs.foregroundColor)
  }
}
