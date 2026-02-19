//
//  SettingBanner.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import SwiftUI

struct SettingBanner {
  let action: () -> Void

  var title: LocalizedStringKey?
  var subtitle: LocalizedStringKey?
  var bannerImage: ImageResource?

  // Spacing
  let topPadding: CGFloat = 16
  let titleToItemSpacing: CGFloat = 12
  let separatorTopPadding: CGFloat = 20
  let separatorBottomPadding: CGFloat = 18
}

extension SettingBanner: View {
  var body: some View {
    Button(action: action) {
      ButtonLabel(
        title: title ?? "",
        subtitle: subtitle ?? "",
        bannerImage: bannerImage
      )
    }
  }
}

extension SettingBanner {
  private struct ButtonLabel: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let bannerImage: ImageResource?

    // Dimensions
    let bannerHeight: CGFloat = 80

    var body: some View {
      RoundedRectangle(cornerRadius: 10, style: .circular)
        .foregroundStyle(SettingsColors.bannerBackground)
        .frame(height: bannerHeight)
        .overlay {
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(title)
                .typo(.sb15)
                .foregroundStyle(.modelPrimary)
              Text(subtitle)
                .font(.pretendard(.medium, size: 12))
                .foregroundStyle(SettingsColors.bannerSubtitle)
            }

            Spacer()

            if let bannerImage {
              Image(bannerImage)
            } else {
              Image(systemName: "xmark")
            }
          }
          .padding(.vertical, 18)
          .padding(.horizontal, 20)
        }
    }
  }
}

extension SettingBanner {
  func title(_ title: LocalizedStringKey) -> Self {
    var body = self
    body.title = title
    return body
  }

  func subtitle(_ subtitle: LocalizedStringKey) -> Self {
    var body = self
    body.subtitle = subtitle
    return body
  }

  func image(_ image: ImageResource) -> Self {
    var body = self
    body.bannerImage = image
    return body
  }
}

#Preview {
  SettingBanner {}
    .title("페어링 방법이 궁금하신가요?")
    .subtitle("새로운 친구를 등록하고 싶어요.")
    .image(.pairGuide)
    .padding(20)
}
