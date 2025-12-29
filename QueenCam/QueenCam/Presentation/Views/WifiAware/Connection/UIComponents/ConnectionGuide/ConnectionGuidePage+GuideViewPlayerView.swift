//
//  ConnectionGuidePage+GuideViewPlayerView.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import AVKit
import SwiftUI

extension ConnectionGuidePage {
  struct GuideViewPlayerView: View {
    let guideVideo: GuideVideo?

    @State private var player: AVPlayer?
    @State private var looper: AVPlayerLooper?

    @State private var isError: Bool = false

    // MARK: Colors
    private let playerBackgroundColor1: Color = .init(red: 0xDA / 255, green: 0xDA / 255, blue: 0xDA / 255, opacity: 0.3)
    private let playerBackgroundColor2: Color = .init(red: 0xDA / 255, green: 0xDA / 255, blue: 0xDA / 255, opacity: 1.0)
    private let playerBorderColor: Color = .init(red: 0x44 / 255, green: 0x44 / 255, blue: 0x44 / 255)

    // MARK: Player Size
    private let playerRatio: CGFloat = 393 / 535

    var body: some View {
      ZStack {
        Color.systemBlack.ignoresSafeArea()

        RadialGradient(
          colors: [
            playerBackgroundColor1,
            playerBackgroundColor2
          ],
          center: .center,
          startRadius: 0,
          endRadius: 340
        )
        .opacity(0.4)
        .ignoresSafeArea()

        if !isError, let player {
          AVPlayerContainer(player: player)
        } else {
          Text("가이딩 비디오를 불러오는 중 문제가 발생했습니다.")
            .typo(.m15)
        }
      }
      .aspectRatio(playerRatio, contentMode: .fit)
      .border(playerBorderColor, width: 1.0)
      .onAppear {
        setupPlayer()
        player?.play()
      }
    }
  }
}

extension ConnectionGuidePage.GuideViewPlayerView {
  private func setupPlayer() {
    isError = false

    if let guideVideo, let videoURL = guideVideo.videoFileURL {
      let playerItem = AVPlayerItem(url: videoURL)
      let player = AVQueuePlayer(playerItem: playerItem)
      self.player = player
      self.looper = AVPlayerLooper(player: player, templateItem: playerItem)
    } else {
      isError = true
    }
  }
}

#Preview {
  ConnectionGuidePage.GuideViewPlayerView(guideVideo: .modelGuide0)
}
