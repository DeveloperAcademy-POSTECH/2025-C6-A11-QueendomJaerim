//
//  PairingGuideSheetView+UIComponents.swift
//  QueenCam
//
//  Created by 임영택 on 9/13/26.
//

import SwiftUI
import UIKit

extension PairingGuideSheetView {
  var topControls: some View {
    HStack {
      Spacer()

      Button(action: closeButtonDidTap) {
        Image(systemName: "xmark")
          .font(.system(size: 20, weight: .regular))
          .foregroundStyle(.systemWhite)
          .frame(width: 45, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("닫기")
      .accessibilityIdentifier("pairing-guide-sheet.close-button")
    }
    .padding(.horizontal, 12)
    .padding(.top, 13)
    .background(Color.gray950.opacity(0.7))
  }

  var guideContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      modeLabel

      Spacer()
        .frame(height: 16)

      Text("페어링을 시작할게요")
        .pairingGuideTypography(.pretendard(.bold, size: 23), lineHeight: 34.5)
        .foregroundStyle(.systemWhite)
        .accessibilityIdentifier("pairing-guide-sheet.title")

      Spacer()
        .frame(height: 8)

      Text("기기 간 연결을 위해, 먼저 페어링을 통해\n기기를 등록하는 과정이 필요해요.")
        .pairingGuideTypography(.pretendard(.medium, size: 14), lineHeight: 22)
        .foregroundStyle(introductionTextColor)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("pairing-guide-sheet.subtitle")

      Spacer()
        .frame(height: 24)

      LazyVStack(spacing: 40) {
        ForEach(items) { item in
          guideItem(item)
        }
      }
    }
    .padding(.top, 10)
    .padding(.horizontal, 20)
  }

  var modeLabel: some View {
    Text(modeTitle)
      .typo(.sb12)
      .foregroundStyle(roleSecondaryColor)
      .padding(.horizontal, 12)
      .frame(height: 26)
      .background(roleDisabledColor, in: Capsule())
      .padding(.leading, -4)
      .accessibilityIdentifier("pairing-guide-sheet.role-label")
  }

  func guideItem(_ item: PairingGuideItem) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        Text("\(item.id)")
          .pairingGuideTypography(.pretendard(.bold, size: 14), lineHeight: 21)
          .foregroundStyle(.gray950)
          .frame(width: 23, height: 23)
          .background(roleStepColor, in: RoundedRectangle(cornerRadius: 6))
          .accessibilityIdentifier("pairing-guide-sheet.step-number-\(item.id)")

        Text(item.title)
          .pairingGuideTypography(.pretendard(.bold, size: 16), lineHeight: 24)
          .foregroundStyle(.systemWhite)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityIdentifier("pairing-guide-sheet.step-title-\(item.id)")
      }

      Text(item.description)
        .pairingGuideTypography(.pretendard(.medium, size: 13), lineHeight: 20)
        .foregroundStyle(.gray500)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)
        .padding(.leading, 35)
        .accessibilityIdentifier("pairing-guide-sheet.step-description-\(item.id)")

      guideImage(for: item)
        .padding(.top, 16)
    }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("pairing-guide-sheet.step-\(item.id)")
  }

  @ViewBuilder
  func guideImage(for item: PairingGuideItem) -> some View {
    if let imageAsset = item.imageAsset {
      Image(imageAsset)
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity)
        .aspectRatio(353 / 213, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityIdentifier("pairing-guide-sheet.step-image-\(item.id)")
    } else {
      RoundedRectangle(cornerRadius: 20)
        .fill(placeholderColor)
        .frame(maxWidth: .infinity)
        .aspectRatio(353 / 213, contentMode: .fit)
        .accessibilityLabel("가이드 이미지 준비 중")
        .accessibilityIdentifier("pairing-guide-sheet.step-placeholder-\(item.id)")
    }
  }

  var bottomControls: some View {
    Button(action: confirmButtonDidTap) {
      Text("이해했어요")
        .typo(.sb16)
        .foregroundStyle(.gray950)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(rolePrimaryColor, in: RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .padding(.top, 20)
    .padding(.horizontal, 16)
    .padding(.bottom, 27)
    .background(
      LinearGradient(
        colors: [Color.gray950.opacity(0), Color.gray950],
        startPoint: .top,
        endPoint: .center
      )
      .ignoresSafeArea()
    )
    .accessibilityIdentifier("pairing-guide-sheet.confirm-button")
  }
}

private extension PairingGuideSheetView {
  var modeTitle: LocalizedStringKey {
    "모델 모드"
  }

  var rolePrimaryColor: Color {
    switch role {
    case .photographer: .photographerPrimary
    case .model: .modelPrimary
    }
  }

  var roleStepColor: Color {
    switch role {
    case .photographer:
      Color(red: 22 / 255, green: 206 / 255, blue: 219 / 255)
    case .model:
      Color(red: 203 / 255, green: 219 / 255, blue: 22 / 255)
    }
  }

  var roleSecondaryColor: Color {
    switch role {
    case .photographer: .photographerS100
    case .model: .modelS100
    }
  }

  var roleDisabledColor: Color {
    switch role {
    case .photographer: .photographerDisabled
    case .model: .modelDisabled
    }
  }
}

private struct PairingGuideTypographyModifier: ViewModifier {
  let font: UIFont
  let lineHeight: CGFloat

  func body(content: Content) -> some View {
    content
      .font(Font(font))
      .lineSpacing(lineHeight - font.lineHeight)
      .padding(.vertical, (lineHeight - font.lineHeight) / 2)
  }
}

private extension View {
  func pairingGuideTypography(_ font: UIFont, lineHeight: CGFloat) -> some View {
    modifier(PairingGuideTypographyModifier(font: font, lineHeight: lineHeight))
  }
}
