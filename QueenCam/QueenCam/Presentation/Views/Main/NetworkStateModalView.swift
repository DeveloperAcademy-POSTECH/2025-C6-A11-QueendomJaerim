//
//  NetworkStateModalView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import SwiftUI

struct NetworkStateModalView {
  let myRole: Role
  var otherRole: Role {
    switch myRole {
    case .photographer:
      return .model
    case .model:
      return .photographer
    }
  }

  let myDeviceName = UIDevice.current.name
  let otherDeviceName: String

  let disconnectButtonDidTap: () -> Void
  let changeRoleButtonDidTap: () -> Void
}

extension NetworkStateModalView: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 20)
      .fill(.gray.opacity(0.2))
      .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
      .frame(width: 340, height: 520)
      .overlay {
        VStack(spacing: 0) {
          RoundedRectangle(cornerRadius: 20)
            .fill(.black.opacity(0.2))
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
            .frame(height: 313)
            .padding(.horizontal, 24)
            .overlay {
              HStack {
                DeviceInfoRowView(isMyInfo: true, role: myRole, deviceName: myDeviceName)

                Spacer()

                DeviceInfoRowView(isMyInfo: false, role: otherRole, deviceName: otherDeviceName)
              }
              .padding(48)
            }

          Spacer().frame(height: 32)

          Button {
            changeRoleButtonDidTap()
          } label: {
            Text("역할 바꾸기")
              .foregroundStyle(.black)
          }
          .frame(width: 293, height: 48)
          .glassEffect()

          Spacer().frame(height: 12)

          Button {
            disconnectButtonDidTap()
          } label: {
            Text("연결 끊기")
              .foregroundStyle(.red)
          }
          .frame(width: 293, height: 48)
          .glassEffect()
        }
      }
  }
}

struct DeviceInfoRowView: View {
  let isMyInfo: Bool
  let role: Role
  let deviceName: String

  var body: some View {
    VStack {
      Text(isMyInfo ? "내 기기" : "상대 기기")

      Spacer()

      Text(role.displayName)

      Spacer()

      Text(deviceName)
        .font(.caption2)
    }
    .frame(maxWidth: .infinity)
  }
}

#Preview {
  NetworkStateModalView(myRole: .model, otherDeviceName: "임영폰") {
    //
  } changeRoleButtonDidTap: {
    //
  }
}
