//
//  SelectRoleView+UIComponents.swift
//  QueenCam
//
//  Created by 임영택 on 11/9/25.
//

import SwiftUI

extension SelectRoleView {
  var individualSymbolOffset: CGFloat { 7.5 }

  var symbolsContainerOffset: CGFloat {  // 선택 시 가운데 정렬
    guard !willShowLoadingAnimation else { return .zero } // 애니메이션 노출 전 원점으로 돌린다

    if selectedRole == .model {
      return -80 + individualSymbolOffset
    } else if selectedRole == .photographer {
      return 80 - individualSymbolOffset
    } else {
      return .zero
    }
  }

  /// 페이지 헤더
  var header: some View {
    VStack(spacing: 18) {
      Text("역할을 선택해주세요")
        .font(.pretendard(.medium, size: 20))

      Text("서로 다른 역할의 기기끼리만\n연결할 수 있어요")
        .multilineTextAlignment(.center)
        .font(.pretendard(.medium, size: 15))
    }
    .foregroundStyle(selectedRole == nil ? .systemWhite : .gray400)
  }

  /// 가운데 역할 선택 버튼
  var roleSelectButtons: some View {
    HStack(spacing: 0) {
      RoleSelectButton {
        didRoleSelect(.photographer)
      }
      .selected(!willShowLoadingAnimation && selectedRole == .photographer)
      .role(.photographer)
      .offset(.init(width: individualSymbolOffset, height: 0))

      RoleSelectButton {
        didRoleSelect(.model)
      }
      .selected(!willShowLoadingAnimation && selectedRole == .model)
      .role(.model)
      .offset(.init(width: -individualSymbolOffset, height: 0))
    }
    .offset(.init(width: symbolsContainerOffset, height: 0))
  }

  @ViewBuilder
  var roleDescriptions: some View {
    if selectedRole == nil {
      VStack(spacing: 15) {
        HStack {
          Spacer()

          Text(Role.photographer.displayName)

          Spacer()

          Text(Role.model.displayName)

          Spacer()
        }
        .typo(.sb20)

        Text("\n") // invisible
          .typo(.sb15)
      }
      .foregroundStyle(.systemWhite)
    } else {
      RoleDescriptionView(role: selectedRole ?? .model)
    }
  }
}
