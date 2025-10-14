//
//  NavigationRouteView.swift
//  QueenCam
//
//  Created by 임영택 on 10/4/25.
//

import SwiftUI

struct NavigationRouteView: View {
  let currentRoute: Route
  let wifiAwareViewModel: WifiAwareViewModel
  let previewModel: PreviewStreamingViewModel

  var body: some View {
    switch currentRoute {
    case .establishConnection:
      ConnectionView(viewModel: wifiAwareViewModel, previewStreamingViewModel: previewModel)
    }
  }
}
