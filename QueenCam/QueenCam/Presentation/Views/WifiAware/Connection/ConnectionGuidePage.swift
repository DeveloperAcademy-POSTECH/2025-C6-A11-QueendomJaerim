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
        .frame(height: 60)

      Text("\(guide.message)")
        .multilineTextAlignment(.center)
        .typo(.m22)
        .foregroundStyle(.systemWhite)
    }
  }
}

#Preview {
  ZStack {
    Color.systemBlack.ignoresSafeArea()

    ConnectionGuidePage(guide: .modelGuides.first!)
  }
}
