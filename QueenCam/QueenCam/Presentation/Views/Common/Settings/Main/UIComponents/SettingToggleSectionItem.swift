//
//  SettingToggleSectionItem.swift
//  QueenCam
//
//  Created by 임영택 on 6/21/26.
//

import SwiftUI

struct SettingToggleSectionItem {
  let title: LocalizedStringKey
  let supplementaryText: LocalizedStringKey?
  @Binding var isOn: Bool

  init(
    title: LocalizedStringKey,
    supplementaryText: LocalizedStringKey? = nil,
    isOn: Binding<Bool>
  ) {
    self.title = title
    self.supplementaryText = supplementaryText
    self._isOn = isOn
  }
}

extension SettingToggleSectionItem: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Toggle(isOn: $isOn) {
        Text(title)
          .typo(.sb16)
          .foregroundStyle(.offWhite)
      }
      .tint(.photographerPrimary)

      if let supplementaryText {
        Text(supplementaryText)
          .typo(.m13)
          .foregroundStyle(.gray600)
      }
    }
  }
}

#Preview {
  @Previewable @State var isOn = true

  ZStack {
    Color.black

    SettingToggleSectionItem(
      title: "사진에 펜 가이드 함께 저장",
      supplementaryText: "촬영자 기준으로 적용되는 설정이에요",
      isOn: $isOn
    )
      .padding(20)
  }
}
