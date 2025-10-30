import SwiftUI

struct BoomupButton {
  
}

extension BoomupButton: View {
  var body: some View {
    Circle()
      .fill(.gray900)
      .frame(width: 48, height: 48)
      .overlay {
        Image(systemName: "hand.thumbsup")
          .font(.system(size: 22))
          .foregroundStyle(.offWhite)
      }
  }
}
