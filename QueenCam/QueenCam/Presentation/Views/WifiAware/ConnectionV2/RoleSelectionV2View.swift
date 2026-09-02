import SwiftUI

struct RoleSelectionV2View: View {
  let selectedRole: Role?
  let roleSelected: (Role) -> Void
  let roleConfirmed: () -> Void
  let closeAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 4) {
        Text("역할을 선택해주세요")
          .typo(.b22)
          .foregroundStyle(.contentPrimary)

        Text("서로 다른 역할의 기기끼리만 연결할 수 있어요.\n친구와 다른 역할을 선택해주세요.")
          .typo(.m14Line22)
          .foregroundStyle(.gray400)
      }

      Spacer(minLength: 48)

      RoleCarouselLayout(selectedRole: selectedRole) {
        roleButton(.photographer)
        roleButton(.model)
      }
      .frame(height: 160)

      roleDescription
        .frame(maxWidth: .infinity)
        .padding(.top, 32)

      Spacer(minLength: 40)
    }
    .padding(.horizontal, 20)
    .padding(.top, 24)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      ConnectionV2PrimaryButton(
        title: selectedRole?.connectionV2StartButtonTitle ?? "역할을 선택해주세요",
        role: selectedRole,
        isEnabled: selectedRole != nil,
        action: roleConfirmed
      )
      .padding(.horizontal, 16)
      .padding(.bottom, 26)
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("닫기", systemImage: "xmark", action: closeAction)
          .labelStyle(.iconOnly)
          .foregroundStyle(.contentPrimary)
      }
    }
  }

  private func roleButton(_ role: Role) -> some View {
    Button {
      roleSelected(role)
    } label: {
      Image(role == .photographer ? .zzikPhotographer : .zzikModel)
        .resizable()
        .scaledToFit()
        .frame(width: 160, height: 160)
        .opacity(selectedRole == nil || selectedRole == role ? 1 : 0.5)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(role.displayName)
    .accessibilityAddTraits(selectedRole == role ? .isSelected : [])
  }

  @ViewBuilder
  private var roleDescription: some View {
    if let selectedRole {
      VStack(spacing: 15) {
        Text(selectedRole.displayName)
          .typo(.sb20)
        Text(selectedRole.userDescription)
          .typo(.m15)
          .multilineTextAlignment(.center)
      }
      .foregroundStyle(.contentPrimary)
    } else {
      HStack(spacing: 0) {
        Text(Role.photographer.displayName)
          .frame(maxWidth: .infinity)
        Text(Role.model.displayName)
          .frame(maxWidth: .infinity)
      }
      .typo(.sb20)
      .foregroundStyle(.contentPrimary)
    }
  }
}

private struct RoleCarouselLayout: Layout {
  let selectedRole: Role?
  private let itemSize: CGFloat = 160
  private let itemStride: CGFloat = 145

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    CGSize(width: proposal.width ?? itemSize * 2, height: itemSize)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    guard subviews.count == 2 else { return }

    let selectedIndex: Int?
    switch selectedRole {
    case .photographer: selectedIndex = 0
    case .model: selectedIndex = 1
    case nil: selectedIndex = nil
    }

    let firstCenterX = selectedIndex.map { bounds.midX - CGFloat($0) * itemStride }
      ?? bounds.midX - itemStride / 2

    for (index, subview) in subviews.enumerated() {
      subview.place(
        at: CGPoint(x: firstCenterX + CGFloat(index) * itemStride, y: bounds.midY),
        anchor: .center,
        proposal: ProposedViewSize(width: itemSize, height: itemSize)
      )
    }
  }
}

#Preview("역할 미선택") {
  NavigationStack {
    RoleSelectionV2View(selectedRole: nil, roleSelected: { _ in }, roleConfirmed: {}, closeAction: {})
  }
  .background(.connectionBackground)
  .preferredColorScheme(.dark)
}

#Preview("촬영 선택") {
  NavigationStack {
    RoleSelectionV2View(
      selectedRole: .photographer,
      roleSelected: { _ in },
      roleConfirmed: {},
      closeAction: {}
    )
  }
  .background(.connectionBackground)
  .preferredColorScheme(.dark)
}
