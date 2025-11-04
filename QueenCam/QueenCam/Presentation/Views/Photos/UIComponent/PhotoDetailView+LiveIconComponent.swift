import SwiftUI

extension PhotoDetailView {
  struct LiveIconComponent {
    let isLivePhoto: Bool
  }
}

extension PhotoDetailView.LiveIconComponent {}

extension PhotoDetailView.LiveIconComponent: View {
  var body: some View {
    if isLivePhoto {
      Rectangle()
        .foregroundColor(.clear)
        .frame(width: 73, height: 23)
        .background(.black.opacity(0.5))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .inset(by: 0.5)
            .stroke(.gray600, lineWidth: 1)
        )
        .overlay {
          HStack(alignment: .center, spacing: 8) {
            Image(systemName: "livephoto")
              .font(Font.custom("SF Pro", size: 12))
              .foregroundStyle(.offWhite)

            Text("LIVE")
              .typo(.sfR13)
              .foregroundColor(.offWhite)
          }
        }
        .padding(.leading, 17)
    }
  }
}

#Preview {
  PhotoDetailView.LiveIconComponent(isLivePhoto: true)
}
