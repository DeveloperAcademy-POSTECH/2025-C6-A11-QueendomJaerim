import AVKit
import SwiftUI

extension ReleaseNoteView {
  /// 릴리즈 노트 안내 영상 플레이어
  ///
  /// 소리 없이 무한 반복 재생하며, 화면을 벗어나면 플레이어를 정리한다.
  struct VideoPlayerView {
    let video: ReleaseNoteVideo

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isError = false

    private let cornerRadius: CGFloat = 12
    private let borderColor: Color = .photographerPrimary.opacity(0.4)
    private let glowColor: Color = .photographerPrimary.opacity(0.35)
  }
}

extension ReleaseNoteView.VideoPlayerView {
  private func setUpPlayer() {
    guard player == nil else { return }

    isError = false

    guard let videoURL = video.videoFileURL else {
      QueenLogger(category: "ReleaseNoteVideoPlayerView")
        .error("안내 영상을 찾을 수 없습니다.")
      isError = true
      return
    }

    let playerItem = AVPlayerItem(url: videoURL)
    let player = AVQueuePlayer(playerItem: playerItem)
    player.isMuted = true

    self.player = player
    self.looper = AVPlayerLooper(player: player, templateItem: playerItem)

    player.play()
  }

  private func tearDownPlayer() {
    player?.pause()
    player = nil
    looper = nil
  }
}

extension ReleaseNoteView.VideoPlayerView: View {
  var body: some View {
    ZStack {
      Color.systemBlack

      if let player {
        AVPlayerContainer(player: player)
      } else if isError {
        Text("영상을 불러오지 못했어요.")
          .typo(.m14)
          .foregroundStyle(.gray400)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 16)
      }
    }
    .clipShape(.rect(cornerRadius: cornerRadius))
    .overlay {
      RoundedRectangle(cornerRadius: cornerRadius)
        .strokeBorder(borderColor, lineWidth: 1)
    }
    .shadow(color: glowColor, radius: 8)
    .onAppear { setUpPlayer() }
    .onDisappear { tearDownPlayer() }
  }
}


#Preview {
  ZStack {
    Color.gray950

    ReleaseNoteView.VideoPlayerView(video: .penGuideOverlay)
      .aspectRatio(241.0 / 321.0, contentMode: .fit)
      .frame(maxWidth: 241)
  }
}
