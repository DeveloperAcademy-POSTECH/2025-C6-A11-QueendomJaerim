//
//  SettingSection.swift
//  QueenCam
//
//  Created by 임영택 on 2/9/26.
//

import SwiftUI

struct SettingSection<Content: View>: View {
  let title: String
  let content: Content

  // Spacing
  var topPadding: CGFloat = 18
  var titleToItemSpacing: CGFloat = 20
  var itemSpacing: CGFloat = 22
  var bottomPadding: CGFloat = 30

  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Spacer()
        .frame(height: topPadding)

      // 섹션 타이틀
      SettingSectionTitle()
        .title(title)

      // 타이틀과 아이템 사이 간격
      Spacer()
        .frame(height: titleToItemSpacing)

      // 아이템 리스트 (VStack 내부 간격 적용)
      VStack(spacing: itemSpacing) {
        content
      }

      // 섹션 종료 후 하단 패딩
      Spacer()
        .frame(height: bottomPadding)

      // 구분선
      Rectangle()
        .frame(height: 1)
        .foregroundStyle(.gray950)
    }
  }
}

// MARK: - Modifiers (간격 조절용)
extension SettingSection {
  func spacing(titleToItem: CGFloat? = nil, item: CGFloat? = nil, bottom: CGFloat? = nil) -> Self {
    var copy = self
    if let titleToItem { copy.titleToItemSpacing = titleToItem }
    if let item { copy.itemSpacing = item }
    if let bottom { copy.bottomPadding = bottom }
    return copy
  }
}

// MARK: - Preview
#Preview {
  ScrollView {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(alignment: .leading, spacing: 0) {
        SettingSection(title: "고객지원") {
          SettingSectionItem {}
            .title("자주하는 질문")

          SettingSectionItem {}
            .title("의견 보내기")
        }

        SettingSection(title: "정보") {
          SettingSectionItem {}
            .title("서비스 이용약관")

          SettingSectionItem {}
            .title("버전 정보")
            .supplementayText("1.2.3")
            .disabled(true)
        }
      }
      .padding(20)
    }
  }
}
