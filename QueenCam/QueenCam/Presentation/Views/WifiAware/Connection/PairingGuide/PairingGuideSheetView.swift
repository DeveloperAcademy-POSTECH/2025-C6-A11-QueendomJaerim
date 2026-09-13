//
//  PairingGuideSheetView.swift
//  QueenCam
//
//  Created by 임영택 on 9/13/26.
//

import SwiftUI

struct PairingGuideItem: Identifiable {
  let id: Int
  let title: LocalizedStringKey
  let description: LocalizedStringKey
  let imageAsset: ImageResource?

  static let defaults: [Self] = [
    .init(
      id: 1,
      title: "양쪽에서 동시에 시도해주세요.",
      description: "모델과 촬영, 양 방향에서 동시에 페어링을 시도해주세요.",
      imageAsset: nil
    ),
    .init(
      id: 2,
      title: "코드 번호를 입력해주세요.",
      description: "촬영자 기기에 나오는 코드를 모델 기기에 입력해주세요.",
      imageAsset: nil
    ),
    .init(
      id: 3,
      title: "페어링이 끝나면 직접 창을 닫아주세요.",
      description: "창이 자동으로 닫히지 않아요.\n페어링이 완료되었다면, 직접 창을 닫아주세요.",
      imageAsset: nil
    )
  ]
}

struct PairingGuideSheetView {
  let role: Role
  let dismissAction: () -> Void
  let items: [PairingGuideItem]

  let maximumContentWidth: CGFloat = 560
  let introductionTextColor = Color(
    red: 172 / 255,
    green: 172 / 255,
    blue: 172 / 255
  )
  let placeholderColor = Color(
    red: 43 / 255,
    green: 43 / 255,
    blue: 43 / 255
  )

  init(
    role: Role,
    items: [PairingGuideItem] = PairingGuideItem.defaults,
    dismissAction: @escaping () -> Void
  ) {
    self.role = role
    self.items = items
    self.dismissAction = dismissAction
  }

  var contentMaxWidth: CGFloat {
    if DynamicModelUtils.isiPad {
      return maximumContentWidth
    }
    return min(UIScreen.main.bounds.width, maximumContentWidth)
  }
}

extension PairingGuideSheetView: View {
  var body: some View {
    ZStack {
      Color.gray950
        .ignoresSafeArea()

      ScrollView(showsIndicators: false) {
        guideContent
          .frame(maxWidth: contentMaxWidth)
          .frame(maxWidth: .infinity)
          .padding(.bottom, 40)
      }
      .accessibilityIdentifier("pairing-guide-sheet.scroll-view")
    }
    .safeAreaInset(edge: .top, spacing: 0) {
      topControls
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity)
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      bottomControls
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity)
    }
    .accessibilityIdentifier("pairing-guide-sheet")
  }
}

extension PairingGuideSheetView {
  func closeButtonDidTap() {
    dismissAction()
  }

  func confirmButtonDidTap() {
    dismissAction()
  }

  func pairingSheetPresentationStyle() -> some View {
    presentationDetents([.large])
      .presentationDragIndicator(.visible)
      .presentationCornerRadius(38)
      .presentationBackground(Color.gray950)
      .presentationContentInteraction(.scrolls)
  }
}

#Preview("촬영 모드") {
  PairingGuideSheetView(role: .photographer) { }
}

#Preview("모델 모드") {
  PairingGuideSheetView(role: .model) { }
}
