import SwiftUI

struct ConnectionV2View: View {
  @Environment(\.dismiss) private var dismiss

  let connectionViewModel: ConnectionViewModel

  var body: some View {
    NavigationStack {
      Group {
        switch connectionViewModel.connectionV2Step {
        case .roleSelection:
          RoleSelectionV2View(
            selectedRole: connectionViewModel.pendingRole,
            roleSelected: connectionViewModel.pendingRoleDidSelect,
            roleConfirmed: connectionViewModel.pendingRoleDidConfirm,
            closeAction: dismiss.callAsFunction
          )
        case .deviceList:
          DeviceConnectionV2View(
            connectionViewModel: connectionViewModel,
            backAction: connectionViewModel.connectionV2BackButtonDidTap,
            closeAction: dismiss.callAsFunction
          )
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.hidden, for: .navigationBar)
      .background(.connectionBackground)
      .overlay {
        ConnectionAttemptOverlay(
          state: connectionViewModel.connectionAttemptState,
          stopAction: connectionViewModel.stopConnectingButtonDidTap,
          closeFailureAction: connectionViewModel.errorConfirmedByUser
        )
      }
    }
    .preferredColorScheme(.dark)
    .trackScreen(.connectionSheet, Self.self)
    .onAppear {
      connectionViewModel.connectionViewAppear()
    }
    .onDisappear {
      connectionViewModel.connectionViewDisappear()
    }
    .onChange(of: connectionViewModel.connections) { _, connections in
      guard !connections.isEmpty else { return }
      Task {
        try? await Task.sleep(for: .milliseconds(800))
        dismiss()
      }
    }
  }
}

#Preview {
  ConnectionV2View(
    connectionViewModel: ConnectionViewModel(
      networkService: NetworkService(),
      notificationService: NotificationService(),
      pairedDeviceRegistry: WAPairedDeviceRegistry.inMemory()
    )
  )
}
