import SwiftUI

extension CameraView {
  struct FocusView {
    @Binding var position: CGPoint
  }
}

extension CameraView.FocusView: View {
  var body: some View {
    Rectangle()
      .frame(width: 70, height: 70)
      .foregroundStyle(.clear)
      .border(Color.yellow, width: 1.5)
      .position(x: position.x, y: position.y)
  }
}
