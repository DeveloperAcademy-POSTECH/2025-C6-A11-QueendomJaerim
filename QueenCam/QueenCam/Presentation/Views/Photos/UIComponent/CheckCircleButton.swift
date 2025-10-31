//
//  CheckCircleButton.swift
//  QueenCam
//
//  Created by 임영택 on 11/1/25.
//

import SwiftUI

struct CheckCircleButton {
  let isSelected: Bool
  let role: Role?
  let isLarge: Bool
  let didTap: () -> Void

  private var outerSize: CGFloat {
    isLarge ? 42 : 24
  }
  private var innerSize: CGFloat {
    isLarge ? 36 : 20
  }

  private let diselectedBorderColor = Color(red: 66 / 255, green: 66 / 255, blue: 66 / 255).opacity(0.7)
  private let diselectedFillColor = Color(red: 217 / 255, green: 217 / 255, blue: 217 / 255).opacity(0.7)
  private var strokeWidth: CGFloat {
    isLarge ? 3 : 2
  }

  // FIXME: 컬러 확정시 변경 예정
  private var keyColor: Color {
    if role == .photographer || role == nil {
      return .photographerPrimary
    } else {
      return .modelPrimary
    }
  }
}

extension CheckCircleButton: View {
  var body: some View {
    Button(
      action: {
        didTap()
      },
      label: {
        Group {
          if isSelected {
            selectedCircle
          } else {
            deselectedCircle
          }
        }
      }
    )
    .frame(width: outerSize, height: outerSize)
  }

  @ViewBuilder
  var selectedCircle: some View {
    ZStack {
      Circle()
        .strokeBorder(keyColor, lineWidth: strokeWidth)

      Circle()
        .fill(keyColor)
        .strokeBorder(.offWhite, lineWidth: strokeWidth)
        .frame(width: innerSize, height: innerSize)
    }
  }

  @ViewBuilder
  var deselectedCircle: some View {
    Circle()
      .strokeBorder(diselectedBorderColor, lineWidth: strokeWidth)
      .fill(diselectedFillColor)
  }
}

#Preview {
  struct CheckCircleButtonPreviewContainer: View {
    @State private var modelCurrentlySelected: Bool = false
    @State private var photographerCurrentlySelected: Bool = false

    var body: some View {
      CheckCircleButton(isSelected: modelCurrentlySelected, role: .model, isLarge: false) {
        modelCurrentlySelected.toggle()
      }

      CheckCircleButton(isSelected: modelCurrentlySelected, role: .model, isLarge: true) {
        modelCurrentlySelected.toggle()
      }

      CheckCircleButton(isSelected: photographerCurrentlySelected, role: .photographer, isLarge: false) {
        photographerCurrentlySelected.toggle()
      }

      CheckCircleButton(isSelected: photographerCurrentlySelected, role: .photographer, isLarge: true) {
        photographerCurrentlySelected.toggle()
      }
    }
  }

  return CheckCircleButtonPreviewContainer()
}
