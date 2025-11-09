//
//  SelectRoleView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import SwiftUI

struct SelectRoleView {
  let selectedRole: Role?
  let didRoleSelect: (Role) -> Void
  let didRoleSubmit: (Role) -> Void

  private let individualSymbolOffset: CGFloat = 7.5

  private var symbolsContainerOffset: CGFloat { // 선택 시 가운데 정렬
    if selectedRole == .model {
      return -80 + individualSymbolOffset
    } else if selectedRole == .photographer {
      return 80 - individualSymbolOffset
    } else {
      return .zero
    }
  }
}

extension SelectRoleView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack {
        Spacer()

        VStack(spacing: 18) {
          Text("역할을 선택해주세요")
            .font(.pretendard(.medium, size: 20))

          Text("서로 다른 역할의 기기끼리만\n연결할 수 있어요")
            .multilineTextAlignment(.center)
            .font(.pretendard(.medium, size: 15))
        }
        .foregroundStyle(selectedRole == nil ? .systemWhite : .gray400)

        Spacer()
          .frame(height: 38)

        roleSelectButtons

        Spacer()
          .frame(height: 38)

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

        Spacer()

        Button {
          if let selectedRole {
            didRoleSubmit(selectedRole)
          }
        } label: {
          Text("기기 연결 시작")
            .font(.pretendard(.medium, size: 16))
            .foregroundColor(selectedRole == nil ? .gray : .white)
            .background(
              Capsule()
                .foregroundStyle(.clear)
            )
            .frame(maxWidth: .infinity, maxHeight: 52)
        }
        .glassEffect(.regular)
      }
      .animation(.linear, value: selectedRole)
      .padding(16)
    }
  }
}

extension SelectRoleView {
  /// 가운데 역할 선택 버튼
  var roleSelectButtons: some View {
    HStack(spacing: 0) {
      RoleSelectButton {
        didRoleSelect(.photographer)
      }
      .selected(selectedRole == nil || selectedRole == .photographer)
      .role(.photographer)
      .offset(.init(width: individualSymbolOffset, height: 0))

      RoleSelectButton {
        didRoleSelect(.model)
      }
      .selected(selectedRole == nil || selectedRole == .model)
      .role(.model)
      .offset(.init(width: -individualSymbolOffset, height: 0))
    }
    .offset(.init(width: symbolsContainerOffset, height: 0))
  }
}

#Preview {
  SelectRoleView(selectedRole: nil) { role in
    //
  } didRoleSubmit: { role in
    //
  }
}
