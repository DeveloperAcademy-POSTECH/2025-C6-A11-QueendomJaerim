//
//  SettingSectionTitle.swift
//  QueenCam
//
//  Created by 임영택 on 2/9/26.
//

import SwiftUI

struct SettingSectionTitle {
  var title: String?
}

extension SettingSectionTitle: View {
  var body: some View {
    HStack {
      Text(title ?? "")
        .typo(.sb14)
        .foregroundStyle(.gray700)

      Spacer()
    }
  }
}

extension SettingSectionTitle {
  func title(_ title: String) -> Self {
    var copy = self
    copy.title = title
    return copy
  }
}

#Preview {
  ZStack {
    Color.black

    SettingSectionTitle()
      .title("찍자 이용 가이드")
  }
  .padding(20)
}
