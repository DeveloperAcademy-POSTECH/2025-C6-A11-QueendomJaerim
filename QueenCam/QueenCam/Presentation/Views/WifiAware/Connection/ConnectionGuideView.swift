//
//  ConnectionGuideView.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import SwiftUI

struct ConnectionGuideView {
  @State var role: Role
  @State var activeIndex: Int? = 0
  var currentGuides: [WifiAwareGuide] {
    if role == .photographer {
      return WifiAwareGuide.photographerGuides
    } else if role == .model {
      return WifiAwareGuide.modelGuides
    }
    return []  // should not reach
  }

  @State var lastPageVisited: Bool = false

  let mainButtonHeight: CGFloat = 52

  let didGuideComplete: () -> Void

  let backButtonDidTap: () -> Void
}

extension ConnectionGuideView: View {
  var body: some View {
    NavigationStack {
      ZStack {
        Color.black.ignoresSafeArea()

        guidePages

        footer
      }
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

      ToolbarItem(placement: .topBarTrailing) {
        if activeIndex != currentGuides.count - 1 {
          Button {
            skipButtonDidTap()
          } label: {
            Text("건너뛰기")
              .typo(.m15)
              .padding(.top, 10)
              .padding(.bottom, 11)
              .padding(.horizontal, 4)
              .foregroundStyle(.gray400)
          }
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
    withAnimation {
      activeIndex = currentGuides.count - 1
    }
  }
}

#Preview {
  ConnectionGuideView(
    role: .model,
    didGuideComplete: {},
    backButtonDidTap: {}
  )
}
