//
//  ConnectionGuideView+UIComponents.swift
//  QueenCam
//
//  Created by 임영택 on 11/9/25.
//

import SwiftUI

extension ConnectionGuideView {
  /// 가이드 설명 페이지
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

  /// 페이지 푸터
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

  /// 가이드 페이지 컨트롤
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
