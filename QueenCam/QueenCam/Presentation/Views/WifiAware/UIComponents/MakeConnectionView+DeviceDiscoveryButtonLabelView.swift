//
//  MakeConnectionView+DeviceDiscoveryButtonLabelView.swift
//  QueenCam
//
//  Created by 임영택 on 11/5/25.
//

import SwiftUI

extension MakeConnectionView {
  struct DeviceDiscoveryButtonLabelView: View {
    let themeColor: Color

    var body: some View {
      HStack {
        Text("주변 기기 찾기")
          .font(.pretendard(.medium, size: 18))
          .foregroundStyle(.offWhite)
          .background(
            Capsule()
              .foregroundStyle(.clear)
          )

        Spacer()

        RoundedRectangle(cornerRadius: 16)
          .foregroundStyle(themeColor)
          .frame(width: 41, height: 33)
          .overlay {
            Image(systemName: "arrow.right")
              .font(.system(size: 16))
              .foregroundStyle(.offWhite)
              .padding()
          }
      }
      .padding(.leading, 24)
      .padding(.trailing, 10)
      .frame(maxWidth: .infinity, maxHeight: 53)
      .glassEffect(.regular)
    }
  }
}

#Preview {
  MakeConnectionView.DeviceDiscoveryButtonLabelView(themeColor: .photographerPrimary)
}
