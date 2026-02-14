//
//  SettingSectionTitle.swift
//  QueenCam
//
//  Created by 임영택 on 2/9/26.
//

import SwiftUI

struct SettingSectionItem {
  let action: () -> Void
  var title: String?
  var supplementayText: String?
  var disabled: Bool = false
}

extension SettingSectionItem: View {
  var body: some View {
    Button(action: action) {
      HStack {
        Text(title ?? "")
          .typo(.sb16)
          .foregroundStyle(.offWhite)

        Spacer()

        if let supplementayText {
          Text(supplementayText)
            .typo(.sb15)
            .foregroundStyle(.gray500)
        } else {
          Image(systemName: "chevron.right")
            .font(.pretendard(.semibold, size: 10))
            .foregroundStyle(.gray500)
        }
      }
      .padding(.trailing, 6)
    }
    .disabled(disabled)
  }
}

extension SettingSectionItem {
  func title(_ title: String) -> Self {
    var copy = self
    copy.title = title
    return copy
  }

  func supplementayText(_ supplementayText: String) -> Self {
    var copy = self
    copy.supplementayText = supplementayText
    return copy
  }

  func disabled(_ disabled: Bool) -> Self {
    var copy = self
    copy.disabled = disabled
    return copy
  }
}

#Preview {
  ZStack {
    Color.black

    VStack(spacing: 22) {
      SettingSectionItem { }
        .title("자주하는 질문")

      SettingSectionItem { }
        .title("버전 정보")
        .supplementayText("1.2.3")
        .disabled(true)
    }
  }
  .padding(20)
}
