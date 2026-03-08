//
//  ConnectionGuideView.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import SwiftUI

struct ConnectionGuideView {
  let role: Role
  let referer: Referer
  @State var activeIndex: Int? = 0
  var currentGuides: [WifiAwareGuide] {
    if role == .photographer {
      return Array(WifiAwareGuide.photographerGuides[0...lastPageIndex])
    } else if role == .model {
      return Array(WifiAwareGuide.modelGuides[0...lastPageIndex])
    }
    return []  // should not reach
  }

  @State var lastPageVisited: Bool = false

  let mainButtonHeight: CGFloat = 52

  let didGuideComplete: () -> Void

  let backButtonDidTap: () -> Void

  // MARK: Computed Values
  var lastPageIndex: Int { referer.lastPageIndex }
  var lastButtonTitle: LocalizedStringKey { referer.lastPageButtonTitle }
}

extension ConnectionGuideView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      guidePages
        .padding(.horizontal, DynamicModelUtils.isiPad ? 48 : 0)

      footer
    }
    .onChange(of: activeIndex) { _, newValue in
      if newValue == currentGuides.count - 1 {
        lastPageVisited = true
      }
    }
    .ignoresSafeArea()
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button("뒤로가기", systemImage: "chevron.left") {
          backButtonDidTap()
        }
      }
    }
  }
}

// MARK: - User Intents
extension ConnectionGuideView {
  func startConnectingButtonDidTap() {
    didGuideComplete()
  }

  func skipButtonDidTap() {
    didGuideComplete()
  }
}

#Preview {
  ConnectionGuideView(
    role: .model,
    referer: .selectRole,
//    referer: .settings,
    didGuideComplete: {},
    backButtonDidTap: {}
  )
}

// MARK: - 어디서 접근했는지 표현하는 열거형
extension ConnectionGuideView {
  enum Referer {
    case selectRole
    case settings

    var lastPageButtonTitle: LocalizedStringKey {
      switch self {
      case .selectRole:
        return "연결 시작하기"
      case .settings:
        return "닫기"
      }
    }

    var lastPageIndex: Int {
      switch self {
      case .selectRole:
        return WifiAwareGuide.modelGuides.count - 1
      case .settings:
        return WifiAwareGuide.modelGuides.count - 2  // 가장 마지막 페이지는 보여주지 않는다
      }
    }
  }
}
