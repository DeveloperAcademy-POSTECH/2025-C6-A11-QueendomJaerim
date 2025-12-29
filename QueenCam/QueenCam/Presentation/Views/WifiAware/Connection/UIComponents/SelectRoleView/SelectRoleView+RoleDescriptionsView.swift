//
//  SelectRoleView+RoleDescriptionsView.swift
//  QueenCam
//
//  Created by 임영택 on 11/9/25.
//

import SwiftUI

extension SelectRoleView {
  struct RoleDescriptionsView {
    /// 선택된 역할. 선택되지 않았으면 nil
    let role: Role?

    /// 유저가 역할을 선택했을 때 실행할 클로져
    let roleSelected: (Role) -> Void

    /// 현재 시스템 로케일을 반환하는 팩토리 클로져
    let localeFactory: () -> (LocaleUtils.Locale)

    init(
      role: Role?,
      localeFactory: @escaping () -> (LocaleUtils.Locale) = { LocaleUtils.currentLocale },
      roleSelected: @escaping (Role) -> Void
    ) {
      self.role = role
      self.localeFactory = localeFactory
      self.roleSelected = roleSelected
    }
  }
}

extension SelectRoleView.RoleDescriptionsView: View {
  var body: some View {
    VStack(spacing: 15) {
      if let role {
        SelectedRoleDescription(displayName: role.displayName, description: role.userDescriptiopn) {
          roleSelected(role)
        }
      } else {
        RoleDescriptions(isFixLabelSpacing: localeFactory() == .korean) { role in
          roleSelected(role)
        }
      }
    }
    .foregroundStyle(.systemWhite)
  }
}

extension SelectRoleView.RoleDescriptionsView {
  private struct SelectedRoleDescription: View {
    let displayName: String
    let description: String
    let tapAction: () -> Void

    private let containerSpacing: CGFloat = 15

    var body: some View {
      VStack(spacing: containerSpacing) {
        Text(displayName)
          .typo(.sb20)
        Text(description)
          .typo(.sb15)
          .multilineTextAlignment(.center)
      }
      .onTapGesture(perform: tapAction)
    }
  }
}

extension SelectRoleView.RoleDescriptionsView {
  private struct RoleDescriptions: View {
    /// 레이블 간의 간격을 고정할지 설정한다. True면 고정한다.
    /// 영어 로케일의 경우 간격을 주면 레이아웃이 깨지므로 불가피하게 false로 지정한다.
    let isFixLabelSpacing: Bool
    let tapAction: (Role) -> Void

    private let containerSpacing: CGFloat = 15

    /// 시각적 균형을 위한 "촬영" - "모델" 레이블 고정 간격 (115 pt)
    private let fixedLabelSpacing: CGFloat = 115

    var body: some View {
      VStack(spacing: containerSpacing) {
        HStack {
          Spacer()

          Text(Role.photographer.displayName)
            .onTapGesture {
              tapAction(.photographer)
            }

          if isFixLabelSpacing {
            Spacer()
              .frame(width: fixedLabelSpacing)
          } else {
            Spacer()
          }

          Text(Role.model.displayName)
            .onTapGesture {
              tapAction(.model)
            }

          Spacer()
        }
        .typo(.sb20)

        Text("\n")  // invisible spacing (sb15 height)
          .typo(.sb15)
      }
    }
  }
}

#Preview {
  @Previewable @State var selectedRole: Role?

  SelectRoleView.RoleDescriptionsView(role: selectedRole) { role in
    if role == selectedRole {
      selectedRole = nil
    } else {
      selectedRole = role
    }
  }
}
