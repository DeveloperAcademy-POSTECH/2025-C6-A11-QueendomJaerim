//
//  SelectRoleView+RoleDescriptionView.swift
//  QueenCam
//
//  Created by 임영택 on 11/9/25.
//

import SwiftUI

extension SelectRoleView {
  struct RoleDescriptionView: View {
    let role: Role
    
    var body: some View {
      VStack(spacing: 15) {
        Text(role.displayName)
          .typo(.sb20)
        Text(role.userDescriptiopn)
          .typo(.sb15)
          .multilineTextAlignment(.center)
      }
      .foregroundStyle(.systemWhite)
    }
  }
}
