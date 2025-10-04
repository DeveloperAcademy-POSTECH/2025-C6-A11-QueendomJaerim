//
//  MainView.swift
//  QueenCam
//
//  Created by 임영택 on 10/4/25.
//

import SwiftUI

struct MainView: View {
  @State private var router = NavigationRouter()

  var body: some View {
    Group {
      NavigationStack(path: $router.path) {
        TestContentView()
          .navigationDestination(for: Route.self) { route in
            NavigationRouteView(currentRoute: route)
          }
      }
    }
    .environment(\.router, router)
  }
}

// TODO: 메인 뷰 구현 후 제거해주세요
private struct TestContentView: View {
  @Environment(\.router) private var router

  var body: some View {
    VStack {
      Text("Main View")

      Button {
        router.push(.establishConnection)
      } label: {
        Text("Go to Establish Connection View")
      }
    }
  }
}

#Preview {
  MainView()
}
