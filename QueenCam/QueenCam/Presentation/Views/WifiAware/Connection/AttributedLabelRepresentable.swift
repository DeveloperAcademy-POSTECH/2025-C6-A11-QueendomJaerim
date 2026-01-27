//
//  AttributedLabelRepresentable.swift
//  QueenCam
//
//  Created by 임영택 on 1/27/26.
//

import SwiftUI

struct AttributedLabelRepresentable: UIViewRepresentable {
  let attributedString: NSAttributedString

  func makeUIView(context: Context) -> UILabel {
    let label = UILabel()
    label.numberOfLines = 0  // multi-lines

    // MARK: Set Layout
    // 수직 방향으로 늘어나지 않게 함
    label.setContentHuggingPriority(.required, for: .vertical)
    // 수직 방향으로 내용이 잘리지 않게 함
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    label.setContentCompressionResistancePriority(.required, for: .vertical)

    return label
  }

  func updateUIView(_ uiView: UILabel, context: Context) {
    uiView.attributedText = attributedString
  }
}
