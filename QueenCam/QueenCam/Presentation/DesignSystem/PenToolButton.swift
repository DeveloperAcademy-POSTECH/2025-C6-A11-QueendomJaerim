import SwiftUI

enum PenToolType {
  case undo
  case eraser
}

struct PenToolButton {
  let penToolType: PenToolType
  let isActive: Bool
  let tapAction: () -> Void
}

extension PenToolButton {
  private var iconName: String {
    switch penToolType {
    case .undo:
      return "arrow.uturn.backward"
    case .eraser:
      return "eraser.fill"
    }
  }
}

extension PenToolButton: View {
  var body: some View {
    Button(action: tapAction) {
      Circle()
        .fill(.black.opacity(0.6))
        .frame(width: 38, height: 38)
        .overlay {
          Image(systemName: iconName)
            .font(.system(size: 13))
            .foregroundStyle(isActive ? .offWhite : .disabled)
        }
    }
    .disabled(!isActive)
  }
}

#Preview {
  HStack(spacing: 16) {
    PenToolButton(penToolType: .undo, isActive: false, tapAction: {})

    PenToolButton(penToolType: .undo, isActive: true, tapAction: {})

    PenToolButton(penToolType: .eraser, isActive: true, tapAction: {})

    PenToolButton(penToolType: .eraser, isActive: false, tapAction: {})

  }
  .padding()
  .background(.gray.opacity(0.3))
}
