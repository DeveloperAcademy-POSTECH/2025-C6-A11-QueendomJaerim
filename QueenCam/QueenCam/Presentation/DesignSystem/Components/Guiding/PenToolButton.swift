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
      return "trash"
    }
  }
}

extension PenToolButton: View {
  var body: some View {
    Button(action: tapAction) {
      Image(systemName: iconName)
        .font(.system(size: 18, weight: .light))
        .frame(height: 21)
        .foregroundStyle(isActive ? .offWhite : .gray600)
    }
    .disabled(!isActive)
  }
}

#Preview {
  HStack(spacing: 16) {
    PenToolButton(penToolType: .undo, isActive: false) {}

    PenToolButton(penToolType: .undo, isActive: true) {}

    PenToolButton(penToolType: .eraser, isActive: true) {}

    PenToolButton(penToolType: .eraser, isActive: false) {}

  }
  .padding()
  .background(.gray.opacity(0.3))
}
