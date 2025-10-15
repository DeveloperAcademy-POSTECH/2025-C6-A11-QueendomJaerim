import SwiftUI

struct PhotoDetailView {
  let image: UIImage
  let onTapAction: () -> Void
  let onTapClose: () -> Void
}

extension PhotoDetailView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      Image(uiImage: image)
        .resizable()
        .scaledToFit()
        .ignoresSafeArea()

      VStack {
        HStack {
          Button(action: { onTapClose() }) {
            Image(systemName: "xmark.circle.fill")
              .font(.title)
              .foregroundStyle(.white.opacity(0.9))
          }

          Spacer()

          Button(action: { onTapAction() }) {
            Text("완료")
              .font(.headline)
              .padding(.horizontal, 20)
              .padding(.vertical, 8)
              .background(Color.blue)
              .foregroundStyle(.white)
              .clipShape(Capsule())
          }
        }
        .padding()

        Spacer()

      }
    }

  }
}

