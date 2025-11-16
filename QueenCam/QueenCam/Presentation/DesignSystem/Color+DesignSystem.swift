import SwiftUI

struct ColorRow: View {
  let color: Color
  let name: String

  var body: some View {
    HStack(spacing: 16) {
      Rectangle()
        .fill(color)
        .frame(width: 80, height: 80)
        .cornerRadius(8)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.black.opacity(0.1))
        )

      Text(name)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.primary)

      Spacer()
    }
  }
}

#Preview {
  ScrollView {
    VStack(spacing: 12) {

      ColorRow(color: .systemBlack, name: "black")
      ColorRow(color: .disabled, name: "disabled")

      Divider()

      ColorRow(color: .gray400, name: "gray400")
      ColorRow(color: .gray600, name: "gray600")
      ColorRow(color: .gray900, name: "gray900")

      Divider()

      ColorRow(color: .modelPrimary, name: "modelPrimary")
      ColorRow(color: .modelS100, name: "modelS100")
      ColorRow(color: .modelDisabled, name: "modelDisabled")

      Divider()

      ColorRow(color: .photographerPrimary, name: "photographerPrimary")
      ColorRow(color: .photographerS100, name: "photographerS100")
      ColorRow(color: .photographerDisabled, name: "photographerDisabled")

      Divider()

      ColorRow(color: .systemWhite, name: "white")
      ColorRow(color: .offWhite, name: "offWhite")
    }
    .padding()
  }
  .background(.gray.opacity(0.1))
}
