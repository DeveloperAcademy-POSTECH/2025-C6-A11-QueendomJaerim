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
      return "eraser"
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
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 20, height: 16)
            .foregroundStyle(isActive ? .offWhite : .disabled)
        }
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
