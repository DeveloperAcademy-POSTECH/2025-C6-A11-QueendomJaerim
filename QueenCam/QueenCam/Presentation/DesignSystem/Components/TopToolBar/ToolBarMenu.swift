//
//  ToolBarMenu.swift
//  QueenCam
//
//  Created by 임영택 on 10/30/25.
//

import SwiftUI

struct ToolBarMenu<MenuContent: View>: View {
  let symbolName: String
  let buttonSize: CGFloat
  @ViewBuilder let menuContent: () -> MenuContent

  private let symbolColor: Color = .white
  private let symbolSize: CGFloat = 17
  private let symbolWeight: Font.Weight = .medium
  private let backgroundColor: Color = .black

  init(symbolName: String, buttonSize: CGFloat = 44, @ViewBuilder menuContent: @escaping () -> MenuContent) {
    self.symbolName = symbolName
    self.buttonSize = buttonSize
    self.menuContent = menuContent
  }

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

#Preview {
  ToolBarMenu(symbolName: "ellipsis") {
    Button("기능 1") { }
  }
}
