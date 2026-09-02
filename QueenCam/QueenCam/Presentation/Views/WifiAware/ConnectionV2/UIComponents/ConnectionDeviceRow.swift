import SwiftUI

struct ConnectionDeviceRow: View {
  let state: ConnectionDeviceRowState
  let connectAction: () -> Void

  var body: some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text(state.name)
          .typo(.m15)
          .foregroundStyle(.contentPrimary)
          .lineLimit(1)

        Text(state.historyStatus.localizedText)
          .typo(state.historyStatus == .newlyRegistered ? .sb12 : .r12)
          .foregroundStyle(state.historyStatus.foregroundStyle)
          .lineLimit(1)
      }

      Spacer(minLength: 8)

      Button("연결", action: connectAction)
        .typo(.sb14)
        .foregroundStyle(.contentPrimary)
        .frame(width: 75, height: 32)
        .background(.gray700, in: .capsule)
        .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .frame(maxWidth: .infinity)
    .frame(height: 75)
    .background(rowBackground, in: .rect(cornerRadius: 12))
  }

  private var rowBackground: Color {
    state.historyStatus == .newlyRegistered ? .gray900 : .gray950
  }
}
