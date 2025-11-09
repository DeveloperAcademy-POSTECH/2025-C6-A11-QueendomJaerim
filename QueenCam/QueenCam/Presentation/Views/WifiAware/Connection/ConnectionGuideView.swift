//
//  ConnectionGuideView.swift
//  QueenCam
//
//  Created by 임영택 on 11/8/25.
//

import SwiftUI

struct ConnectionGuideView {
  @Environment(\.router) private var router

  @State var role: Role
  @State private var activeIndex: Int? = 0
  private var currentGuides: [WifiAwareGuide] {
    if role == .photographer {
      return WifiAwareGuide.photographerGuides
    } else if role == .model {
      return WifiAwareGuide.modelGuides
    }
    return []  // should not reach
  }

  @State private var lastPageVisited: Bool = false

  private let mainButtonHeight: CGFloat = 52
}

extension ConnectionGuideView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      guidePages

      footer
    }
    .onChange(of: activeIndex) { _, newValue in
      if newValue == currentGuides.count - 1 {
        lastPageVisited = true
      }
    }
    .ignoresSafeArea()
    .toolbar {
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

  var guidePages: some View {
    GeometryReader { geometry in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 0) {
          ForEach(0..<currentGuides.count, id: \.self) { index in
            ConnectionGuidePage(guide: currentGuides[index])
              .frame(width: geometry.size.width)
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.paging)
      .scrollPosition(id: $activeIndex)
    }
  }

  var footer: some View {
    VStack(spacing: 0) {
      Spacer()

      pagingControl

      Spacer()
        .frame(height: 36)

      Button {
        startConnectingButtonDidTap()
      } label: {
        Text("연결 시작하기")
          .typo(.sb16)
          .foregroundColor(.offWhite)
          .background(
            Capsule()
              .foregroundStyle(.clear)
          )
          .frame(maxWidth: .infinity, maxHeight: mainButtonHeight)
      }
      .glassEffect()
      .opacity(lastPageVisited ? 1.0 : 0.0)

      Spacer()
        .frame(height: 48)
    }
    .animation(.easeInOut, value: lastPageVisited)
  }
}

extension ConnectionGuideView {
  var pagingControl: some View {
    HStack {
      ForEach(0..<currentGuides.count, id: \.self) { index in
        let regularColor = Color(red: 0x2E / 255, green: 0x2E / 255, blue: 0x2E / 255)
        let selectedColor = Color(red: 0x97 / 255, green: 0x97 / 255, blue: 0x97 / 255)

        Button {
          withAnimation {
            self.activeIndex = index
          }
        } label: {
          Image(systemName: "circle.fill")
            .resizable()
            .foregroundStyle(self.activeIndex == index ? selectedColor : regularColor)
            .frame(width: 8, height: 8)
        }
      }
    }
  }
}

extension ConnectionGuideView {
  // MARK: - User Intents

  private func startConnectingButtonDidTap() {
    router.push(.makeConnection)
  }

  private func skipButtonDidTap() {
    withAnimation {
      activeIndex = currentGuides.count - 1
    }
  }
}

#Preview {
  ConnectionGuideView(role: .model)
}
