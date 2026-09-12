//
//  SelectRoleViewV2+TransitionAnimationView.swift
//  QueenCam
//
//  Created by 임영택 on 9/6/26.
//

import SwiftUI

extension SelectRoleViewV2 {
  struct TransitionAnimationView: View {
    @State private var phase: TransitionAnimationPhase = .off

    let animationDidFinish: () -> Void

    var body: some View {
      GeometryReader { proxy in
        Image(phase == .off ? .loadingAnimationOff : .loadingAnimationOn)
          .resizable()
          .scaledToFit()
          .frame(height: RoleButtonMetrics.size)
          .position(x: proxy.size.width / 2, y: RoleButtonMetrics.buttonsCenterY)
          .accessibilityIdentifier("select-role-v2.transition-animation")
      }
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          withAnimation(.linear) {
            phase = .on
          }

          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animationDidFinish()
          }
        }
      }
    }
  }
}

private enum TransitionAnimationPhase {
  case off
  case on
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()

    SelectRoleViewV2.TransitionAnimationView {}
  }
}
