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
        VStack(alignment: .center, spacing: 8) {
          Button(action: { tapAction() }) {
            Image(iconName)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 23, height: 22)
          }

          Text(title)
            .typo(.sfR11)

        }
        .foregroundStyle(
          isDisabeld
            ? (isActive ? .modelDisabled : .disabled)
            : (isActive ? .modelPrimary : .systemWhite)
        )

      case .photographer:
        VStack(alignment: .center, spacing: 8) {
          Button(action: { tapAction() }) {
            Image(iconName)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 23, height: 22)
          }

          Text(title)
            .typo(.sfR11)
        }
        .foregroundStyle(
          isDisabeld
            ? (isActive ? .photographerDisabled : .disabled)
            : (isActive ? .photographerPrimary : .systemWhite)
        )

      case .none:
        VStack(alignment: .center, spacing: 8) {
          Button(action: { tapAction() }) {
            Image(iconName)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 23, height: 22)
          }

          Text(title)
            .typo(.sfR11)
        }
        .foregroundStyle(
          isDisabeld
            ? (isActive ? .photographerDisabled : .disabled)
            : (isActive ? .photographerPrimary : .systemWhite)
        )
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
