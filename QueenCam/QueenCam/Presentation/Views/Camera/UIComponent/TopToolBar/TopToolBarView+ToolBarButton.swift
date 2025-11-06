//
//  TopToolBarView+ToolBarButton.swift
//  QueenCam
//
//  Created by 임영택 on 10/30/25.
//

import SwiftUI

extension TopToolBarView {
  struct ToolBarButton {
    let symbolName: String
    let buttonSize: CGFloat
    let buttonDidTap: () -> Void

    private let symbolColor: Color = .white
    private let symbolSize: CGFloat = 17
    private let symbolWeight: Font.Weight = .medium
    private let backgroundColor: Color = .black

    init(symbolName: String, buttonSize: CGFloat = 44, buttonDidTap: @escaping () -> Void) {
      self.symbolName = symbolName
      self.buttonSize = buttonSize
      self.buttonDidTap = buttonDidTap
    }
  }
}

extension TopToolBarView.ToolBarButton: View {
  var body: some View {
    Button(action: buttonDidTap) {
      Image(systemName: symbolName)
        .font(.system(size: symbolSize, weight: symbolWeight))
        .foregroundStyle(symbolColor)
        .frame(width: buttonSize, height: buttonSize)
        .glassEffect(.regular.tint(backgroundColor), in: .circle)
    }
  }
}
