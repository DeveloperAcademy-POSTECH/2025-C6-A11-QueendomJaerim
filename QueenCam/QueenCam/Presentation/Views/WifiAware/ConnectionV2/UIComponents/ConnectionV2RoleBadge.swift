import SwiftUI

struct ConnectionV2RoleBadge: View {
  let role: Role
  var showsSwapButton = false
  var swapAction: (() -> Void)?

  var body: some View {
    HStack(spacing: 8) {
      Text(role.connectionV2ModeName)
        .typo(.sb12)
        .foregroundStyle(role.connectionV2SecondaryColor)
        .padding(.horizontal, 12)
        .frame(height: 26)
        .background(role.connectionV2DisabledColor, in: .capsule)

      if showsSwapButton {
        Button {
          swapAction?()
        } label: {
          Image(systemName: "arrow.left.arrow.right")
            .font(.system(size: 11))
            .foregroundStyle(.contentPrimary)
            .frame(width: 26, height: 26)
        }
        .buttonStyle(.plain)
        .background(.gray700, in: .circle)
        .accessibilityLabel("역할 바꾸기")
      }
    }
  }
}

#Preview {
  VStack {
    ConnectionV2RoleBadge(role: .photographer, showsSwapButton: true) {}
    ConnectionV2RoleBadge(role: .model, showsSwapButton: true) {}
  }
  .padding()
  .background(.connectionBackground)
}
