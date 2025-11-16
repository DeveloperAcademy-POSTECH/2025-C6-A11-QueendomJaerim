import SwiftUI

struct GuidingToggleButton {
  let role: Role?
  let systemName: String
  let isActive: Bool
  let buttonSize: CGFloat
  let tapAction: () -> Void

  init(role: Role?, systemName: String, isActive: Bool, buttonSize: CGFloat = 40, tapAction: @escaping () -> Void) {
    self.role = role
    self.systemName = systemName
    self.isActive = isActive
    self.buttonSize = buttonSize
    self.tapAction = tapAction
  }
}

extension GuidingToggleButton: View {
  var body: some View {
    Group {
      switch self.role {
      case .model:
        Button(action: { tapAction() }) {
          Circle()
            .fill(.black.opacity(0.6))
            .frame(width: buttonSize, height: buttonSize)
            .overlay {
              Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 22.5, height: 13.5)
                .foregroundStyle(isActive ? .modelPrimary : .offWhite)
            }
        }

      case .photographer:
        Button(action: { tapAction() }) {
          Circle()
            .fill(.black.opacity(0.6))
            .frame(width: buttonSize, height: buttonSize)
            .overlay {
              Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 22.5, height: 13.5)
                .foregroundStyle(isActive ? .photographerPrimary : .offWhite)
            }
        }

      case .none:
        Button(action: { tapAction() }) {
          Circle()
            .fill(.black.opacity(0.6))
            .frame(width: buttonSize, height: buttonSize)
            .overlay {
              Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 22.5, height: 13.5)
                .foregroundStyle(isActive ? .photographerPrimary : .offWhite)
            }
        }
      }
    }
  }
}

#Preview {
  VStack {
    GuidingToggleButton(role: .none, systemName: "eye.slash", isActive: false) {}
    GuidingToggleButton(role: .photographer, systemName: "eye", isActive: true) {}
    GuidingToggleButton(role: .model, systemName: "eye", isActive: true) {}
  }
}
