import SwiftUI

struct GridView {
}

extension GridView: View {
  var body: some View {
    GeometryReader { geometry in

      let width = geometry.size.width
      let height = geometry.size.height
      let xSpacing = width / 3
      let ySpacing = height / 3

      Path { path in
        for index in 1..<3 {
          let xOffset: CGFloat = CGFloat(index) * xSpacing
          path.move(to: CGPoint(x: xOffset, y: 0))
          path.addLine(to: CGPoint(x: xOffset, y: height))
        }

        for index in 1..<3 {
          let yOffset: CGFloat = CGFloat(index) * ySpacing
          path.move(to: CGPoint(x: 0, y: yOffset))
          path.addLine(to: CGPoint(x: width, y: yOffset))
        }
      }
      .stroke(.white.opacity(0.5), lineWidth: 1)
    }
  }
}
