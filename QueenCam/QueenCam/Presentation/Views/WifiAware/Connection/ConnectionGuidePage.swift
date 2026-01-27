//
//  ConnectionGuidePage.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import AVFoundation
import SwiftUI

struct ConnectionGuidePage: View {
  let guide: WifiAwareGuide

  let mediumTypography = TypographyStyle.m22
  let boldTypography = TypographyStyle.b22

  var body: some View {
    VStack(spacing: 0) {
      GuideViewPlayerView(guideVideo: guide.video)

      Spacer()
        .frame(height: 60)

      AttributedContentsView(attributedContents: guide.message) { style in
        switch style {
        case .highlighted:
          return .init(font: boldTypography.font, foregroundColor: guide.type == .model ? .modelPrimary : .photographerPrimary)
        case .normal:
          return .init(font: mediumTypography.font, foregroundColor: .systemWhite)
        }
      }
      .multilineTextAlignment(.center)
      .kerning(mediumTypography.letterSpacing)
      .lineSpacing(mediumTypography.lineSpacing)
      .padding(.vertical, mediumTypography.verticalPadding)
    }
  }
}

#Preview {
  ZStack {
    Color.systemBlack.ignoresSafeArea()

    ConnectionGuidePage(guide: .modelGuides.first!)
  }
}
