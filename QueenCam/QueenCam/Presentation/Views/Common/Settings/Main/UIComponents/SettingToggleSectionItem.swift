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
  let isHighlight: Bool
  @Binding var isOn: Bool

  init(
    title: LocalizedStringKey,
    supplementaryText: LocalizedStringKey? = nil,
    isHighlight: Bool = false,
    isOn: Binding<Bool>
  ) {
    self.title = title
    self.supplementaryText = supplementaryText
    self.isHighlight = isHighlight
    self._isOn = isOn
  }
}

extension SettingToggleSectionItem {
  /// 강조 상태의 항목
  ///
  /// 제목과 토글이 함께 두 번 흐려졌다 돌아오고, 그 사이에 제목만 한 번 빛난다.
  private var highlightToggle: some View {
    KeyframeAnimator(initialValue: HighlightPhase()) { phase in
      toggle(glow: phase.glow)
        .opacity(phase.opacity)
    } keyframes: { _ in
      KeyframeTrack(\.opacity) {
        CubicKeyframe(HighlightPhase.dimmedOpacity, duration: 0.56)
        CubicKeyframe(1.0, duration: 0.14)
        CubicKeyframe(HighlightPhase.dimmedOpacity, duration: 0.56)
        CubicKeyframe(1.0, duration: 0.14)
        CubicKeyframe(1.0, duration: 0.60)
      }

      KeyframeTrack(\.glow) {
        LinearKeyframe(0.0, duration: 0.56)
        CubicKeyframe(1.0, duration: 0.15)
        CubicKeyframe(0.0, duration: 0.56)
        LinearKeyframe(0.0, duration: 0.73)
      }
    }
  }

  private func toggle(glow: Double) -> some View {
    Toggle(isOn: $isOn) {
      Text(title)
        .typo(.sb16)
        .foregroundStyle(.offWhite)
        .shadow(color: .offWhite.opacity(glow), radius: 5)
    }
    .tint(.photographerPrimary)
  }
}

extension SettingToggleSectionItem: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if isHighlight {
        highlightToggle
      } else {
        toggle(glow: .zero)
      }

      if let supplementaryText {
        Text(supplementaryText)
          .typo(.m13)
          .foregroundStyle(.gray600)
      }
    }
  }
}

extension SettingToggleSectionItem {
  private struct HighlightPhase {
    static let dimmedOpacity: Double = 0.5

    var opacity: Double = 1.0
    var glow: Double = 0.0
  }
}

#Preview {
  @Previewable @State var isOn = true

  ZStack {
    Color.black

    SettingToggleSectionItem(
      title: "사진에 펜 가이드 함께 저장",
      supplementaryText: "촬영자 기준으로 적용되는 설정이에요",
      isHighlight: true,
      isOn: $isOn
    )
      .padding(20)
  }
}
