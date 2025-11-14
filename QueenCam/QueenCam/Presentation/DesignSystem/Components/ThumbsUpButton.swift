import SwiftUI

struct ThumbsUpButton {
  let tapAction: () -> Void
}

extension ThumbsUpButton: View {
  var body: some View {
    Button(action: { tapAction() }) {
      Circle()
        .fill(.gray900)
        .frame(width: 48, height: 48)
        .overlay {
          Image(systemName: "hand.thumbsup")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 29, height: 29)
            .foregroundStyle(.offWhite)
        }
    }
  }
}

#Preview {
  ThumbsUpButton(tapAction: { })
}
