//
//  SelectRoleViewV2.swift
//  QueenCam
//
//  Created by 임영택 on 9/6/26.
//

import SwiftUI

struct SelectRoleViewV2 {
  enum RoleButtonMetrics {
    static let size: CGFloat = 160
    static let overlap: CGFloat = 15
    static let buttonsTopOffset: CGFloat = 342
    static let descriptionSpacing: CGFloat = 33
    static let labelSpacing: CGFloat = 1
    static let buttonCount = 2

    static let stride = size - overlap
    static let centersSpan = stride * CGFloat(buttonCount - 1)
    static let selectedOffset = centersSpan / 2
    static let buttonsCenterY = buttonsTopOffset + size / 2
    static let descriptionTopOffset = buttonsTopOffset + size + descriptionSpacing
    static let labelsWidth = stride * CGFloat(buttonCount)
      + labelSpacing * CGFloat(buttonCount - 1)
    static let unconstrainedButtonsWidth = size * CGFloat(buttonCount)
  }

  @Environment(\.dismiss) private var dismiss

  let selectedRole: Role?
  let didRoleSelect: (Role) -> Void
  let didRoleSubmit: () -> Void

  @State private var willShowLoadingAnimation = false
  @State private var isShowingLoadingAnimation = false
  @State private var loadingAnimationDidComplete = false

  private let backgroundColor = Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
}

extension SelectRoleViewV2: View {
  var body: some View {
    ZStack {
      backgroundColor

      if isShowingLoadingAnimation {
        TransitionAnimationView {
          loadingAnimationDidComplete = true
        }
      } else {
        selectionContent
      }
    }
    .ignoresSafeArea()
    .toolbar(.hidden, for: .navigationBar)
    .onChange(of: loadingAnimationDidComplete) { _, didComplete in
      guard didComplete else { return }

      if selectedRole != nil {
        didRoleSubmit()
      }

      Task {
        isShowingLoadingAnimation = false
        loadingAnimationDidComplete = false
      }
    }
  }

  private var selectionContent: some View {
    GeometryReader { proxy in
      ZStack(alignment: .topLeading) {
        Color.clear
          .contentShape(Rectangle())
          .accessibilityIdentifier("select-role-v2.screen")

        header
          .offset(x: 20, y: 155)

        roleSelectButtons
          .frame(width: proxy.size.width, height: RoleButtonMetrics.size)
          .offset(y: RoleButtonMetrics.buttonsTopOffset)

        roleDescription
          .frame(width: proxy.size.width)
          .offset(y: RoleButtonMetrics.descriptionTopOffset)

        primaryButton
          .frame(width: max(proxy.size.width - 32, 0), height: 56)
          .position(x: proxy.size.width / 2, y: proxy.size.height - 88)

        closeButton
          .position(x: proxy.size.width - 32.5, y: 92.5)
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .contentShape(Rectangle())
      .gesture(horizontalSwipeGesture)
    }
  }
}

private extension SelectRoleViewV2 {
  var header: some View {
    VStack(alignment: .leading, spacing: 9) {
      Text("역할을 선택해주세요")
        .typo(.b22)
        .foregroundStyle(.systemWhite)
        .accessibilityIdentifier("select-role-v2.title")

      Text("서로 다른 역할의 기기끼리만 연결할 수 있어요.\n친구와 다른 역할을 선택해주세요.")
        .typo(.m14)
        .foregroundStyle(.gray400)
        .accessibilityIdentifier("select-role-v2.subtitle")
    }
  }

  var roleSelectButtons: some View {
    RoleSelectButtonsLayout {
      roleButton(for: .photographer)
      roleButton(for: .model)
    }
    .compositingGroup()
    .offset(x: roleSelectButtonsOffset)
    .animation(.linear, value: roleSelectButtonsOffset)
  }

  var roleSelectButtonsOffset: CGFloat {
    guard !willShowLoadingAnimation else { return .zero }

    return switch selectedRole {
    case .photographer: RoleButtonMetrics.selectedOffset
    case .model: -RoleButtonMetrics.selectedOffset
    case nil: .zero
    }
  }

  func roleButton(for role: Role) -> some View {
    Button {
      didRoleSelect(role)
    } label: {
      Image(role == .photographer ? .zzikPhotographer : .zzikModel)
        .resizable()
        .frame(width: RoleButtonMetrics.size, height: RoleButtonMetrics.size)
        .opacity(!willShowLoadingAnimation && selectedRole == role ? 1 : 0.5)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(role.displayName)
    .accessibilityIdentifier(
      role == .photographer
        ? "select-role-v2.photographer-button"
        : "select-role-v2.model-button"
    )
    .accessibilityAddTraits(selectedRole == role ? .isSelected : [])
  }

  @ViewBuilder
  var roleDescription: some View {
    if let selectedRole {
      Button {
        didRoleSelect(selectedRole)
      } label: {
        VStack(spacing: 15) {
          Text(selectedRole.displayName)
            .typo(.sb20)

          Text(selectedRole.userDescriptiopn)
            .typo(.m15)
            .multilineTextAlignment(.center)
        }
        .foregroundStyle(.systemWhite)
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("select-role-v2.selected-role-description")
    } else {
      HStack(spacing: RoleButtonMetrics.labelSpacing) {
        roleLabelButton(for: .photographer)
        roleLabelButton(for: .model)
      }
      .frame(width: RoleButtonMetrics.labelsWidth)
    }
  }

  func roleLabelButton(for role: Role) -> some View {
    Button {
      didRoleSelect(role)
    } label: {
      Text(role.displayName)
        .typo(.sb20)
        .foregroundStyle(.systemWhite)
        .frame(width: RoleButtonMetrics.stride)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(
      role == .photographer
        ? "select-role-v2.photographer-label"
        : "select-role-v2.model-label"
    )
  }

  var primaryButton: some View {
    Button {
      guard selectedRole != nil else { return }

      withAnimation {
        willShowLoadingAnimation = true
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        withAnimation {
          willShowLoadingAnimation = false
        }
        isShowingLoadingAnimation = true
      }
    } label: {
      Text(primaryButtonTitle)
        .typo(.sb16)
        .foregroundStyle(.systemBlack)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(primaryButtonColor, in: RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
    .disabled(selectedRole == nil)
    .accessibilityIdentifier("select-role-v2.primary-button")
  }

  var primaryButtonTitle: LocalizedStringKey {
    switch selectedRole {
    case .photographer: "촬영으로 시작하기"
    case .model: "모델로 시작하기"
    case nil: "역할을 선택해주세요"
    }
  }

  var primaryButtonColor: Color {
    switch selectedRole {
    case .photographer: .photographerPrimary
    case .model: .modelPrimary
    case nil: .gray950
    }
  }

  var closeButton: some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: "xmark")
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(.offWhite)
        .frame(width: 45, height: 45)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("닫기")
    .accessibilityIdentifier("select-role-v2.close-button")
  }

  var horizontalSwipeGesture: some Gesture {
    DragGesture(minimumDistance: 30, coordinateSpace: .local)
      .onEnded { value in
        guard abs(value.translation.width) > abs(value.translation.height) else { return }
        didSwipe(direction: value.translation.width)
      }
  }

  func didSwipe(direction: CGFloat) {
    guard selectedRole != nil else { return }

    if direction < .zero && selectedRole != .model {
      didRoleSelect(.model)
    }

    if direction > .zero && selectedRole != .photographer {
      didRoleSelect(.photographer)
    }
  }
}

private struct RoleSelectButtonsLayout: Layout {
  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    CGSize(
      width: proposal.width ?? SelectRoleViewV2.RoleButtonMetrics.unconstrainedButtonsWidth,
      height: SelectRoleViewV2.RoleButtonMetrics.size
    )
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    guard subviews.count == SelectRoleViewV2.RoleButtonMetrics.buttonCount else { return }

    let firstCenterX = bounds.midX - SelectRoleViewV2.RoleButtonMetrics.selectedOffset

    for (index, subview) in subviews.enumerated() {
      subview.place(
        at: CGPoint(
          x: firstCenterX + CGFloat(index) * SelectRoleViewV2.RoleButtonMetrics.stride,
          y: bounds.midY
        ),
        anchor: .center,
        proposal: ProposedViewSize(
          width: SelectRoleViewV2.RoleButtonMetrics.size,
          height: SelectRoleViewV2.RoleButtonMetrics.size
        )
      )
    }
  }
}

#Preview("역할 미선택") {
  @Previewable @State var selectedRole: Role?

  SelectRoleViewV2(
    selectedRole: selectedRole,
    didRoleSelect: { role in
      selectedRole = selectedRole == role ? nil : role
    },
    didRoleSubmit: {}
  )
}
