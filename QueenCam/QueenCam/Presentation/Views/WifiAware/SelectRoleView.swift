//
//  SelectRoleView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import SwiftUI

struct SelectRoleView: View {
  let selectedRole: Role?
  let didRoleSelect: (Role) -> Void
  let didRoleSubmit: (Role) -> Void

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
        .foregroundStyle(.offWhite)

        Spacer()
          .frame(height: 38)

        HStack {
          RoleSelectButton(guideText: "이 기기로 찍을게요", roleText: "촬영") {
            didRoleSelect(.photographer)
          }
          .selected(selectedRole == .photographer)

          RoleSelectButton(guideText: "이 기기로 볼게요", roleText: "모델") {
            didRoleSelect(.model)
          }
          .selected(selectedRole == .model)
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
      .padding(16)
    }
  }
}

#Preview {
  SelectRoleView(selectedRole: nil) { role in
    //
  } didRoleSubmit: { role in
    //
  }

}
