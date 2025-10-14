//
//  SelectRoleView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import SwiftUI

struct SelectRoleView: View {
  let didRoleSelect: (Role) -> Void

  var body: some View {
    VStack {
      Text("역할을 선택해주세요")
        .fontWeight(.bold)

      Text("서로 다른 역할의 기기끼리만 연결할 수 있어요")

      Spacer()
        .frame(height: 60)

      HStack {
        RoleSelectButton(guideText: "이 기기로 찍을게요", roleText: "촬영") {
          didRoleSelect(.photographer)
        }

        RoleSelectButton(guideText: "이 기기로 볼게요", roleText: "모델") {
          didRoleSelect(.model)
        }
      }
    }
  }
}
