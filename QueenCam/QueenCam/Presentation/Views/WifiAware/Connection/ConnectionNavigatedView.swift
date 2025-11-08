//
//  ConnectionNavigatedView.swift
//  QueenCam
//
//  Created by 임영택 on 11/4/25.
//

import SwiftUI

struct ConnectionNavigatedView: View {
  let route: Route
  let connectionViewModel: ConnectionViewModel

  var body: some View {
    switch route {
    case .makeConnection:
      if let role = connectionViewModel.role {
        MakeConnectionView(
          role: role,
          networkState: connectionViewModel.networkState,
          selectedPairedDevice: connectionViewModel.selectedPairedDevice,
          pairedDevices: connectionViewModel.pairedDevices,
          changeRoleButtonDidTap: {
            connectionViewModel.selectRole(for: connectionViewModel.role?.counterpart)
          },
          connectButtonDidTap: { device in
            connectionViewModel.connectButtonDidTap(for: device)
          }
        )
      } else { // should not reach
        Text("역할이 지정되지 않았습니다.")
          .typo(.r12)
      }
    case .connectionGuide:
      if let role = connectionViewModel.role {
        ConnectionGuideView(role: role)
      } else {
        Text("역할이 지정되지 않았습니다.")
          .typo(.r12)
      }
    }
  }
}
