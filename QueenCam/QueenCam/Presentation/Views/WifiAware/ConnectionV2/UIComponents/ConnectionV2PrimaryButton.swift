import SwiftUI

struct ConnectionV2PrimaryButton: View {
  let title: LocalizedStringKey
  let role: Role?
  let isEnabled: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ConnectionV2PrimaryButtonLabel(title: title, role: role, isEnabled: isEnabled)
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
  }
}

struct ConnectionV2PrimaryButtonLabel: View {
  let title: LocalizedStringKey
  let role: Role?
  let isEnabled: Bool

  var body: some View {
    Text(title)
      .typo(.sb16)
      .foregroundStyle(foregroundColor)
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(backgroundColor, in: .rect(cornerRadius: 12))
  }

  private var backgroundColor: Color {
    guard isEnabled, let role else { return .gray900 }
    return role.connectionV2PrimaryColor
  }

  private var foregroundColor: Color {
    isEnabled ? .gray950 : .gray600
  }
}

#Preview {
  VStack {
    ConnectionV2PrimaryButton(title: "역할을 선택해주세요", role: nil, isEnabled: false) {}
    ConnectionV2PrimaryButton(title: "촬영으로 시작하기", role: .photographer, isEnabled: true) {}
    ConnectionV2PrimaryButton(title: "모델로 시작하기", role: .model, isEnabled: true) {}
  }
  .padding()
  .background(.connectionBackground)
}
