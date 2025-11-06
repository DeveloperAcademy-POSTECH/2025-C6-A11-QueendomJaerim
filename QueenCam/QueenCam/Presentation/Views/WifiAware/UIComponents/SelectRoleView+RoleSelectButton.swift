//
//  SelectRoleView+RoleSelectButton.swift
//  QueenCam
//
//  Created by 임영택 on 11/4/25.
//

import Foundation
import SwiftUI

extension SelectRoleView {
  struct RoleSelectButton: View {
    let roleText: LocalizedStringKey
    let action: () -> Void

    var isSelected = false
    var themeColor = Color(.photographerPrimary)

    var body: some View {
      Button(action: action) {
        VStack(spacing: 38) {
          Image(.zzikSymbol)
            .renderingMode(.template)
            .foregroundStyle(isSelected ? .offWhite : themeColor)
            .frame(width: 147)

          Text(roleText)
            .font(.pretendard(.medium, size: 20))
            .foregroundStyle(.offWhite)
        }
      }
    }
  }
}

extension SelectRoleView.RoleSelectButton {
  func selected(_ selected: Bool = true) -> Self {
    var newButton = self
    newButton.isSelected = selected

    return newButton
  }

  func themeColor(_ color: Color) -> Self {
    var newButton = self
    newButton.themeColor = color

    return newButton
  }
}

#Preview {
  ZStack {
    Color.black
    SelectRoleView.RoleSelectButton(roleText: "작가") {
      //
    }
  }
}
