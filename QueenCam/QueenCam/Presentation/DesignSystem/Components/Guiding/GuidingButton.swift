import SwiftUI

enum GuidingButtonType {
  case frame
  case pen
  case magicPen
}

struct GuidingButton {
  let role: Role?
  let isActive: Bool
  let isDisabeld: Bool
  let tapAction: () -> Void
  let guidingButtonType: GuidingButtonType
}

extension GuidingButton {
  private var title: String {
    switch guidingButtonType {
    case .frame:
      "프레임"
    case .pen:
      "펜"
    case .magicPen:
      "매직펜"
    }
  }

  private var iconName: String {
    switch guidingButtonType {
    case .frame:
      return "square.dashed"
    case .pen:
      return "stylus_note"
    case .magicPen:
      return "wand_shine"
    }
  }
}

extension GuidingButton: View {
  var body: some View {
    Group {
      switch self.role {
      case .model:
        Button(action: { tapAction() }) {
          VStack(alignment: .center, spacing: 6) {
            Image(iconName)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 21, height: 21)
              .padding(3)

            Text(title)
              .typo(.sfR10)
          }
          .foregroundStyle(
            isDisabeld
              ? (isActive ? .modelDisabled : .disabled)
              : (isActive ? .modelPrimary : .systemWhite)
          )
          .padding(5)
        }

      case .photographer:
        Button(action: { tapAction() }) {
          VStack(alignment: .center, spacing: 6) {
            Image(iconName)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 21, height: 21)
              .padding(3)

            Text(title)
              .typo(.sfR10)
          }
          .foregroundStyle(
            isDisabeld
              ? (isActive ? .photographerDisabled : .disabled)
              : (isActive ? .photographerPrimary : .systemWhite)
          )
          .padding(5)
        }

      case .none:
        Button(action: { tapAction() }) {
          VStack(alignment: .center, spacing: 6) {
            Image(iconName)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 21, height: 21)
              .padding(3)

            Text(title)
              .typo(.sfR10)
          }
          .foregroundStyle(
            isDisabeld
              ? (isActive ? .photographerDisabled : .disabled)
              : (isActive ? .photographerPrimary : .systemWhite)
          )
          .padding(5)
        }
      }
    }
  }
}

#Preview {
  ScrollView {
    VStack(spacing: 32) {
      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .none, isActive: false, isDisabeld: false, tapAction: {}, guidingButtonType: .frame)

        GuidingButton(role: .none, isActive: false, isDisabeld: false, tapAction: {}, guidingButtonType: .pen)
        GuidingButton(role: .none, isActive: false, isDisabeld: false, tapAction: {}, guidingButtonType: .magicPen)
      }

      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .model, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .frame)

        GuidingButton(role: .model, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .pen)

        GuidingButton(role: .model, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .magicPen)
      }

      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .photographer, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .frame)

        GuidingButton(role: .photographer, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .pen)

        GuidingButton(role: .photographer, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .magicPen)

      }

      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .model, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .frame)

        GuidingButton(role: .model, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .pen)

        GuidingButton(role: .model, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .magicPen)

      }

      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .photographer, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .frame)

        GuidingButton(role: .photographer, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .pen)

        GuidingButton(role: .photographer, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .magicPen)

      }

      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .photographer, isActive: false, isDisabeld: true, tapAction: {}, guidingButtonType: .frame)

        GuidingButton(role: .photographer, isActive: false, isDisabeld: true, tapAction: {}, guidingButtonType: .pen)

        GuidingButton(role: .photographer, isActive: false, isDisabeld: true, tapAction: {}, guidingButtonType: .magicPen)

      }
    }
    .padding(.top, 120)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(.black.opacity(0.9))
}
