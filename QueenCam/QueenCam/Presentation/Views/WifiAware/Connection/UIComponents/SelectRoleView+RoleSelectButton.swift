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
    let action: () -> Void

    var isSelected = false
    var role: Role = .model

    private let imageRenderingSize: CGFloat = 160

    var body: some View {
      Image(role == .model ? .zzikModel : .zzikPhotographer)
        .resizable()
        .frame(width: imageRenderingSize, height: imageRenderingSize)
        .opacity(isSelected ? 1.0 : 0.5)
        .onTapGesture(perform: action)
    }
  }
}

extension SelectRoleView.RoleSelectButton {
  func selected(_ selected: Bool = true) -> Self {
    var newButton = self
    newButton.isSelected = selected

    return newButton
  }

  func role(_ role: Role) -> Self {
    var newButton = self
    newButton.role = role

    return newButton
  }
}

#Preview {
  ZStack {
    Color.black
    SelectRoleView.RoleSelectButton {
      //
    }
    .role(.photographer)
  }
}
