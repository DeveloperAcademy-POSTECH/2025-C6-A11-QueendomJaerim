//
//  NetworkToolbarView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import SwiftUI

struct NetworkToolbarView: View {
  let networkState: NetworkState
  let connectedDeviceName: String?
  let buttonDidTap: () -> Void

  var body: some View {
    HStack {
      Spacer()

      Button {
        buttonDidTap()
      } label: {
        if let connectedDeviceName {
          NetworkToolbarButtonLabel(isDotShowing: true, title: connectedDeviceName)
        } else {
          NetworkToolbarButtonLabel(isDotShowing: false, title: "연결하기")
        }
      }
      .glassEffect(.regular.tint(.black).interactive())

      Spacer()
    }
  }
}

struct NetworkToolbarButtonLabel: View {
  let isDotShowing: Bool
  let title: String
  
  var body: some View {
    HStack(spacing: 0) {
      if isDotShowing {
        Circle()
          .foregroundStyle(.red)
          .frame(width: 6, height: 6)
        
        Spacer()
          .frame(width: 10)
      }
      
      Text(title)
        .font(.system(size: 16))
        .foregroundStyle(.white)
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
  }
}

#Preview {
  VStack {
    // swiftlint:disable:next no_print_in_production
    NetworkToolbarView(connectedDeviceName: nil) { print("Button Tapped") }
    // swiftlint:disable:next no_print_in_production
    NetworkToolbarView(connectedDeviceName: "윤보라의 iPhone 17 Air") { print("Button Tapped") }
  }
}
