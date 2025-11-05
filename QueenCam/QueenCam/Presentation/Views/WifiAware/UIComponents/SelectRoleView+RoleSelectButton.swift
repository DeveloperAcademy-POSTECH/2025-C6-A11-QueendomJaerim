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
    let guideText: LocalizedStringKey
    let roleText: LocalizedStringKey
    let action: () -> Void

    var isSelected = false

    var body: some View {
      Button {
        action()
      } label: {
        RoundedRectangle(cornerRadius: 23)
          .frame(width: 171, height: 247)
          .foregroundStyle(.gray)
          .overlay {
            VStack {
              Text(guideText)

              Spacer()

              Text(roleText)
            }
            .foregroundStyle(isSelected ? .black : .white)
            .padding()
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
}
