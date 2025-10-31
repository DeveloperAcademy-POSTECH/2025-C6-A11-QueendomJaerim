import SwiftUI

struct GuidingToggleButton {
  let role: Role?
  let systemName: String
  let isActive: Bool
  let tapAction: () -> Void
}

extension GuidingToggleButton: View {
  var body: some View {
    Group {
      switch self.role {
      case .model:
        Button(action: { tapAction() }) {
          Circle()
            .fill(.black.opacity(0.6))
            .frame(width: 38, height: 38)
            .overlay {
              Image(systemName: systemName)
                .font(.system(size: 12))
                .foregroundStyle(isActive ? .modelPrimary : .offWhite)
            }
        }

      case .photographer:
        Button(action: { tapAction() }) {
          Circle()
            .fill(.black.opacity(0.6))
            .frame(width: 38, height: 38)
            .overlay {
              Image(systemName: systemName)
                .font(.system(size: 12))
                .foregroundStyle(isActive ? .photographerPrimary : .offWhite)
            }
        }

      case .none:
        Button(action: { tapAction() }) {
          Circle()
            .fill(.black.opacity(0.6))
            .frame(width: 38, height: 38)
            .overlay {
              Image(systemName: systemName)
                .font(.system(size: 12))
                .foregroundStyle(isActive ? .photographerPrimary : .offWhite)
            }
        }
      }
    }
  }
}

#Preview {
  VStack {
    GuidingToggleButton(role: .none, systemName: "eye.slash", isActive: false, tapAction: {})
    GuidingToggleButton(role: .photographer, systemName: "eye", isActive: true, tapAction: {})
    GuidingToggleButton(role: .model, systemName: "eye", isActive: true, tapAction: {})
  }
}
