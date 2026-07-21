//
//  SettingToggleSectionItem.swift
//  QueenCam
//
//  Created by 임영택 on 6/21/26.
//

import SwiftUI

struct SettingToggleSectionItem {
  let title: LocalizedStringKey
  @Binding var isOn: Bool
}

extension SettingToggleSectionItem: View {
  var body: some View {
    Toggle(isOn: $isOn) {
      Text(title)
        .typo(.sb16)
        .foregroundStyle(.offWhite)
    }
    .tint(.photographerPrimary)
  }
}

#Preview {
  @Previewable @State var isOn = true

  ZStack {
    Color.black

    SettingToggleSectionItem(title: "펜 가이드 함께 저장", isOn: $isOn)
      .padding(20)
  }
}
