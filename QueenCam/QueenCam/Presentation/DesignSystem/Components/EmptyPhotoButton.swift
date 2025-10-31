import SwiftUI

struct EmptyPhotoButton {

}

extension EmptyPhotoButton: View {
  var body: some View {
    Image("photos")
      .resizable()
      .scaledToFit()
      .frame(width: 48, height: 48)
  }
}

#Preview {
  VStack {
    EmptyPhotoButton()
  }
  .frame(width: 300, height: 300)
  .background(.gray)
}
