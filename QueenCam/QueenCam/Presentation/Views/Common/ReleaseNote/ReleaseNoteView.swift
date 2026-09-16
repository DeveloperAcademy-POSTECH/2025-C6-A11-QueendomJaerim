import SwiftUI

/// 앱을 업데이트한 뒤 처음 실행할 때 새 기능을 알리는 화면
struct ReleaseNoteView {
  let releaseNote: ReleaseNote
  let onStart: () -> Void
  let onClose: () -> Void

  private let videoAspectRatio: CGFloat = 241.0 / 321.0
  private let videoMaxWidth: CGFloat = 241
}

extension ReleaseNoteView {
  private var content: some View {
    VStack(spacing: 0) {
      Text(releaseNote.badge)
        .typo(.sb14)
        .foregroundStyle(.photographerPrimary)

      title
        .padding(.top, 17)

      Text(releaseNote.subtitle)
        .typo(.m14)
        .foregroundStyle(.gray400)
        .padding(.top, 12)

      VideoPlayerView(videoURL: releaseNote.videoFileURL)
        .aspectRatio(videoAspectRatio, contentMode: .fit)
        .frame(maxWidth: videoMaxWidth)
        .padding(.top, 54)

      Spacer(minLength: 24)

      startButton
    }
    .multilineTextAlignment(.center)
    .padding(.top, 113)
    .padding(.bottom, 60)
    .padding(.horizontal, 16)
  }

  private var title: some View {
    VStack(spacing: 0) {
      ForEach(Array(releaseNote.titleLines.enumerated()), id: \.offset) { _, line in
        Text(line.text)
          .typo(.b24)
          .foregroundStyle(line.isHighlighted ? Color.photographerPrimary : Color.offWhite)
      }
    }
  }

  private var startButton: some View {
    Button(action: onStart) {
      Text(releaseNote.actionTitle)
        .typo(.sb16)
        .foregroundStyle(.systemBlack)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(.photographerPrimary)
        .clipShape(.rect(cornerRadius: 12))
    }
  }

  private var closeButton: some View {
    Button(action: onClose) {
      Image(systemName: "xmark")
        .font(.system(size: 16))
        .foregroundStyle(.offWhite)
        .frame(width: 45, height: 45)
    }
  }
}

extension ReleaseNoteView: View {
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Background()

      content

      closeButton
        .padding(.top, 70)
        .padding(.trailing, 8)
    }
    .ignoresSafeArea()
  }
}

#Preview {
  ReleaseNoteView(releaseNote: .current) {
    //
  } onClose: {
    //
  }
}
