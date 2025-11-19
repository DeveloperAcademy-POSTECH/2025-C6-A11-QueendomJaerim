import SwiftUI

enum GuidingButtonType {
  case frame
  case frameChecked
  case pen
  case penChecked
  case magicPen
  case magicPenChecked
}

struct GuidingButton {
  let role: Role?
  let isActive: Bool
  let isDisabeld: Bool
  let tapAction: () -> Void
  let guidingButtonType: GuidingButtonType

  private let symbolHeight: CGFloat = 21
  private let symbolPadding: CGFloat = 3
  private let symbolLabelSpacing: CGFloat = 2
  private let buttonPadding: CGFloat = 5
}

extension GuidingButton {
  private var title: String {
    switch guidingButtonType {
    case .frame:
      "프레임"
    case .frameChecked:
      "프레임"
    case .pen:
      "펜"
    case .penChecked:
      "펜"
    case .magicPen:
      "매직펜"
    case .magicPenChecked:
      "매직펜"
    }
  }

  private var iconImageResource: ImageResource {
    switch guidingButtonType {
    case .frame:
      return .squareDashed
    case .frameChecked:
      return .squareDashedCheck
    case .pen:
      return .stylusNote
    case .penChecked:
      return .stylusNoteCheck
    case .magicPen:
      return .wandShine
    case .magicPenChecked:
      return .wandShineCheck
    }
  }
}

extension GuidingButton: View {
  var body: some View {
    Group {
      switch self.role {
      case .model:
        Button(action: { tapAction() }) {
          VStack(alignment: .center, spacing: symbolLabelSpacing) {
            Image(iconImageResource)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(height: symbolHeight)
              .padding(symbolPadding)

            Text(title)
              .typo(.sfR10)
          }
          .foregroundStyle(
            isDisabeld
              ? (isActive ? .modelDisabled : .disabled)
              : (isActive ? .modelPrimary : .systemWhite)
          )
          .padding(buttonPadding)
        }

      case .photographer:
        Button(action: { tapAction() }) {
          VStack(alignment: .center, spacing: symbolLabelSpacing) {
            Image(iconImageResource)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(height: symbolHeight)
              .padding(symbolPadding)

            Text(title)
              .typo(.sfR10)
          }
          .foregroundStyle(
            isDisabeld
              ? (isActive ? .photographerDisabled : .disabled)
              : (isActive ? .photographerPrimary : .systemWhite)
          )
          .padding(buttonPadding)
        }

      case .none:
        Button(action: { tapAction() }) {
          VStack(alignment: .center, spacing: symbolLabelSpacing) {
            Image(iconImageResource)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(height: symbolHeight)
              .padding(symbolPadding)

            Text(title)
              .typo(.sfR10)
          }
          .foregroundStyle(
            isDisabeld
              ? (isActive ? .photographerDisabled : .disabled)
              : (isActive ? .photographerPrimary : .systemWhite)
          )
          .padding(buttonPadding)
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
        GuidingButton(role: .none, isActive: false, isDisabeld: false, tapAction: {}, guidingButtonType: .frameChecked)

        GuidingButton(role: .none, isActive: false, isDisabeld: false, tapAction: {}, guidingButtonType: .pen)
        GuidingButton(role: .none, isActive: false, isDisabeld: false, tapAction: {}, guidingButtonType: .penChecked)

        GuidingButton(role: .none, isActive: false, isDisabeld: false, tapAction: {}, guidingButtonType: .magicPen)
        GuidingButton(role: .none, isActive: false, isDisabeld: false, tapAction: {}, guidingButtonType: .magicPenChecked)
      }

      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .model, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .frame)
        GuidingButton(role: .model, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .frameChecked)

        GuidingButton(role: .model, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .pen)
        GuidingButton(role: .model, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .penChecked)

        GuidingButton(role: .model, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .magicPen)
        GuidingButton(role: .model, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .magicPenChecked)
      }

      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .photographer, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .frame)
        GuidingButton(role: .photographer, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .frameChecked)

        GuidingButton(role: .photographer, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .pen)
        GuidingButton(role: .photographer, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .penChecked)

        GuidingButton(role: .photographer, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .magicPen)
        GuidingButton(role: .photographer, isActive: true, isDisabeld: false, tapAction: {}, guidingButtonType: .magicPenChecked)
      }

      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .model, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .frame)
        GuidingButton(role: .model, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .frameChecked)

        GuidingButton(role: .model, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .pen)
        GuidingButton(role: .model, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .penChecked)

        GuidingButton(role: .model, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .magicPen)
        GuidingButton(role: .model, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .magicPenChecked)
      }

      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .photographer, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .frame)
        GuidingButton(role: .photographer, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .frameChecked)

        GuidingButton(role: .photographer, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .pen)
        GuidingButton(role: .photographer, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .penChecked)

        GuidingButton(role: .photographer, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .magicPen)
        GuidingButton(role: .photographer, isActive: true, isDisabeld: true, tapAction: {}, guidingButtonType: .magicPenChecked)
      }

      HStack(alignment: .center, spacing: 40) {
        GuidingButton(role: .photographer, isActive: false, isDisabeld: true, tapAction: {}, guidingButtonType: .frame)
        GuidingButton(role: .photographer, isActive: false, isDisabeld: true, tapAction: {}, guidingButtonType: .frameChecked)

        GuidingButton(role: .photographer, isActive: false, isDisabeld: true, tapAction: {}, guidingButtonType: .pen)
        GuidingButton(role: .photographer, isActive: false, isDisabeld: true, tapAction: {}, guidingButtonType: .penChecked)

        GuidingButton(role: .photographer, isActive: false, isDisabeld: true, tapAction: {}, guidingButtonType: .magicPen)
        GuidingButton(role: .photographer, isActive: false, isDisabeld: true, tapAction: {}, guidingButtonType: .magicPenChecked)
      }
    }
    .padding(.top, 120)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(.black.opacity(0.9))
}
