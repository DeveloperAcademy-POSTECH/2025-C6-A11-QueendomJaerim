//
//  MakeConnectionView+ToolBar.swift
//  QueenCam
//
//  Created by 임영택 on 11/5/25.
//

import SwiftUI

extension MakeConnectionView {
  struct ToolBar {
    // MARK: Properties
    let role: Role
    
    // MARK: Actions
    let changeRoleButtonDidTap: () -> Void
    
    // MARK: Computed
    private var myDeviceName: String {
      UIDevice.current.name
    }

    // MARK: Colors
    let changeRoleButtonForegroundColor = Color(red: 0xC2 / 255, green: 0xC2 / 255, blue: 0xC2 / 255)
    let guidingLabelColor = Color(red: 0x98 / 255, green: 0x98 / 255, blue: 0x98 / 255)
  }
}

extension MakeConnectionView.ToolBar: View {
  var body: some View {
    // MARK: - 툴바
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 8) {
        Text("다음 이름으로 보여집니다")
          .foregroundStyle(guidingLabelColor)
          .font(.pretendard(.medium, size: 14))
        Text("\(myDeviceName)")
          .foregroundStyle(.offWhite)
          .font(.pretendard(.medium, size: 18))
      }

      Spacer()

      Button(action: changeRoleButtonDidTap) {
        HStack(alignment: .center, spacing: 4) {
          Text(role.currentModeLabel)
            .font(.pretendard(.medium, size: 14))

          Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
            .font(.system(size: 11))
        }
        .foregroundStyle(changeRoleButtonForegroundColor)
        .padding(.vertical, 12)
        .padding(.leading, 19)
        .padding(.trailing, 15)
      }
      .glassEffect(.regular)
    }
  }
}

private extension Role {
  var currentModeLabel: String {
    switch self {
    case .model: "모델 모드"
    case .photographer: "작가 모드"
    }
  }
}
