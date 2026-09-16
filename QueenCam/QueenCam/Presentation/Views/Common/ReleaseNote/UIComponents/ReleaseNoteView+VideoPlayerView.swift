import AVKit
import SwiftUI

extension ReleaseNoteView {
  /// 릴리즈 노트 안내 영상 플레이어
  ///
  /// 소리 없이 무한 반복 재생하며, 화면을 벗어나면 플레이어를 정리한다.
  struct VideoPlayerView {
    let videoURL: URL?

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var pauseObservation: NSKeyValueObservation?
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

    guard let videoURL else {
      QueenLogger(category: "ReleaseNoteVideoPlayer")
        .error("안내 영상을 찾을 수 없습니다.")
      isError = true
      return
    }

    let playerItem = AVPlayerItem(url: videoURL)

    // AVPlayerLooper가 큐를 직접 관리하므로 플레이어는 비어 있는 상태로 만든다
    let player = AVQueuePlayer()
    player.isMuted = true

    self.player = player
    self.looper = AVPlayerLooper(player: player, templateItem: playerItem)

    observeUnexpectedPause(player: player)

    player.play()
  }

  /// 카메라 세션이 오디오 세션을 재구성하면서 재생이 멈추면 다시 시작한다
  ///
  /// 안내 영상은 소리가 없어 재개해도 촬영에 영향을 주지 않는다.
  private func observeUnexpectedPause(player: AVQueuePlayer) {
    pauseObservation = player.observe(\.timeControlStatus, options: [.new]) { player, _ in
      guard player.timeControlStatus == .paused else { return }

      player.play()
    }
  }

  private func tearDownPlayer() {
    pauseObservation?.invalidate()
    pauseObservation = nil

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

    ReleaseNoteView.VideoPlayerView(videoURL: ReleaseNote.current.videoFileURL)
      .aspectRatio(241.0 / 321.0, contentMode: .fit)
      .frame(maxWidth: 241)
  }
}
