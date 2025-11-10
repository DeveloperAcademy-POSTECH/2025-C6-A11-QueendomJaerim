//
//  SelectRoleView+TransitionAnimationView.swift
//  QueenCam
//
//  Created by 임영택 on 11/9/25.
//

import SwiftUI

extension SelectRoleView {
  struct TransitionAnimationView: View {
    @State private var phase: TransitionAnimationPhase = .off

    let animationDidFinish: () -> Void

    var body: some View {
      VStack {
        Spacer()

        Image(phase == .off ? .loadingAnimationOff : .loadingAnimationOn)
          .resizable()
          .scaledToFit()
          .frame(height: 160)

        Spacer()
      }
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          withAnimation(.linear) {
            self.phase = .on
          }

          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.animationDidFinish()
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

    SelectRoleView.TransitionAnimationView {
      // swiftlint:disable:next no_print_in_production
      print("애니메이션 종료")
    }
  }
}
