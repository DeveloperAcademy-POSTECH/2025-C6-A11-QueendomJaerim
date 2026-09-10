import SwiftUI

extension ReleaseNoteView {
  struct Background { }
}

extension ReleaseNoteView.Background: View {
  var body: some View {
    GeometryReader { proxy in
      Image(.releaseNoteBackground)
        .resizable()
        .scaledToFill()
        .frame(width: proxy.size.width, height: proxy.size.height)
        .clipped()
    }
    .ignoresSafeArea()
  }
}

#Preview {
  ReleaseNoteView.Background()
}
