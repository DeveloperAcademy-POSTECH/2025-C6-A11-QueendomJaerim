//
//  NavigationRouter.swift
//  QueenCam
//
//  Created by 임영택 on 10/4/25.
//

import SwiftUI

@Observable
final class NavigationRouter {
  var path: [Route] = []

  func push(_ route: Route) {
    path.append(route)
  }

  func pop() {
    if !path.isEmpty {
      path.removeLast()
    }
  }

  func reset() {
    path = []
  }
}
