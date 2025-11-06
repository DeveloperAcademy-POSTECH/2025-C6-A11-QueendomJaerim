//
//  TopToolBarView+ToolBarMenu.swift
//  QueenCam
//
//  Created by 임영택 on 10/30/25.
//

import SwiftUI

extension TopToolBarView {
  struct ToolBarMenu {
    let symbolName: String
    let buttonSize: CGFloat
    @ViewBuilder let menuContent: () -> ContextMenuContent

    private let symbolColor: Color = .white
    private let symbolSize: CGFloat = 17
    private let symbolWeight: Font.Weight = .medium
    private let backgroundColor: Color = .black

    init(symbolName: String, buttonSize: CGFloat = 44, @ViewBuilder menuContent: @escaping () -> ContextMenuContent) {
      self.symbolName = symbolName
      self.buttonSize = buttonSize
      self.menuContent = menuContent
    }
  }
}

extension TopToolBarView.ToolBarMenu: View {
  var body: some View {
    Menu(content: menuContent) {
      Image(systemName: symbolName)
        .font(.system(size: symbolSize, weight: symbolWeight))
        .foregroundStyle(symbolColor)
        .frame(width: buttonSize, height: buttonSize)
        .glassEffect(.regular.tint(backgroundColor), in: .circle)
    }
  }
}
