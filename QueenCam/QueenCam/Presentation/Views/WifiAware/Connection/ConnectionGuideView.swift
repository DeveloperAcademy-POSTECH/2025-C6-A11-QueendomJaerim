//
//  ConnectionGuideView.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import AVFoundation
import SwiftUI

struct ConnectionGuideView: View {
  // MARK: States
  @State var role: Role
  @State private var index: Int = 0 {
    willSet {
      if newValue > maxIndex {
        self.index = newValue
      }
    }
  }
  private let maxIndex = 2 // 마지막 페이지 인덱스
  private var guideVideo: GuideVideo? {
    GuideVideo.getByRoleAndIndex(role: role, index: index)
  }

  var body: some View {
    VStack(spacing: 0) {
      GuideViewPlayerView(guideVideo: guideVideo)

      VStack(spacing: 0) {
        Text("페어링이 왜 필요해요?")

        Text("'주변 기기 찾기'를 시작해\n친구에게 페어링을 요청해주세요.")
      }
    }
  }
}

#Preview {
  ConnectionGuideView(role: .model)
}
