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

  var body: some View {
    VStack(spacing: 0) {
      GuideViewPlayerView(guideVideo: guide.video)

      Spacer()
        .frame(height: 31)

      VStack(spacing: 0) {
        Text("페어링이 왜 필요해요?")
          .typo(.sb12)
          .foregroundStyle(.gray400)
          .underline()

        Spacer()
          .frame(height: 26)

        Text("\(guide.message)")
          .multilineTextAlignment(.center)
          .typo(.m22)
          .foregroundStyle(.systemWhite)
      }
    }
  }
}

#Preview {
  ZStack {
    Color.systemBlack.ignoresSafeArea()

    ConnectionGuidePage(guide: .modelGuides.first!)
  }
}
