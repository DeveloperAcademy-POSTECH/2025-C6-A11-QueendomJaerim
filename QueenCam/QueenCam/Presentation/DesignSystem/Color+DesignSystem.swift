import SwiftUI

#Preview {
  ScrollView {
    VStack(spacing: 12) {

      ColorRow(color: .black, name: "black")
      ColorRow(color: .disabled, name: "disabled")

      Divider()

      ColorRow(color: .gray400, name: "gray400")
      ColorRow(color: .gray600, name: "gray600")
      ColorRow(color: .gray900, name: "gray900")

      Divider()

      ColorRow(color: .modelPrimary, name: "modelPrimary")
      ColorRow(color: .photographerPrimary, name: "photographerPrimary")

      Divider()

      ColorRow(color: .white, name: "white")
      ColorRow(color: .offWhite, name: "offWhite")
    }
    .padding()
  }
  .background(.gray.opacity(0.1))
}

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
