import SwiftUI

struct ThumbsUpView {
  var thumbsUpViewModel: ThumbsUpViewModel

  @State private var isWiggling = false
}

extension ThumbsUpView {}

extension ThumbsUpView: View {
  var body: some View {
    VStack {
      if let label = thumbsUpViewModel.testString {
        Text(label)
          .font(.headline)
          .foregroundStyle(.clear)
          .padding()
      }

      Image("thumbs_up")
        .resizable()
        .frame(width: 300, height: 300)
        .foregroundStyle(.red)
        .rotationEffect(.degrees(isWiggling ? -30 : 10))
        .onAppear {
          // 이미지가 흔들리는 시간
          withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            isWiggling.toggle()
          }
        }
    }
  }
}
