//
//  SelectRoleView.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import SwiftUI

struct SelectRoleView {
  @Environment(\.dismiss) private var dismiss

  let selectedRole: Role?
  let didRoleSelect: (Role) -> Void
  let didRoleSubmit: () -> Void

  @State var willShowLoadingAnimation: Bool = false
  @State private var isShowLoadingAnimation: Bool = false
  @State private var loadingAnimationDidComplete: Bool = false

  // MARK: Spacing
  private let topSpacing: CGFloat = 115
  private let bottomSpacing: CGFloat = 90
}

extension SelectRoleView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      if isShowLoadingAnimation {
        TransitionAnimationView {
          self.loadingAnimationDidComplete = true
        }
      } else {
        ZStack {
          roleSelectButtons // 애니메이션 연결을 위해 화면 세로 가운데 정렬

          VStack {
            Spacer()
              .frame(height: 115)

            header

            Spacer() // 가운데에는 역할 선택 버튼이 들어가야하므로 비어둔다

            roleDescriptions

            Spacer()
              .frame(height: 90)

            Button {
              if selectedRole != nil {
                withAnimation {
                  willShowLoadingAnimation = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                  willShowLoadingAnimation = false
                  isShowLoadingAnimation = true
                }
              }
            } label: {
              Text("연결하기")
                .font(.pretendard(.semibold, size: 16))
                .foregroundColor(.offWhite)
                .background(
                  Capsule()
                    .foregroundStyle(.clear)
                )
                .frame(maxWidth: .infinity, maxHeight: 52)
            }
            .glassEffect(.regular)
            .disabled(selectedRole == nil)
            .opacity(selectedRole == nil ? 0.0 : 1.0)
          }
          .padding(16)
        }
        .animation(.linear, value: selectedRole)
        .gesture(
          DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
              if abs(value.translation.width) > abs(value.translation.height) {  // 수평 스크롤 판별
                self.didSwipe(direction: value.translation.width)
              }
            }
        )
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigation) {
        if !isShowLoadingAnimation {
          Button("닫기", systemImage: "chevron.left") {
            dismiss()
          }
        }
      }

      ToolbarItem(placement: .principal) {
        Text("") // 애니메이션 중 닫기 버튼 사라져도 툴바가 유지되어야 레이아웃이 깨지지 않음
      }
    }
    .navigationBarTitleDisplayMode(.inline) // LargeTitle 영역 제외
    .onChange(of: loadingAnimationDidComplete) { _, newValue in
      if newValue {
        if selectedRole != nil {
          self.didRoleSubmit()
        }

        Task { // 다음 사이클에서 상태 초기화
          self.isShowLoadingAnimation = false
          self.loadingAnimationDidComplete = false
        }
      }
    }
  }
}

extension SelectRoleView {
  func didSwipe(direction: CGFloat) {
    guard selectedRole != nil else { return }  // 이미 역할이 선택된 경우만 스와이프하여 역할을 스위칭할 수 있음

    if direction < .zero && selectedRole != .model {  // 왼쪽으로 스와이프한 경우
      didRoleSelect(.model)
    }

    if direction > .zero && selectedRole != .photographer {  // 오른쪽으로 스와이프한 경우
      didRoleSelect(.photographer)
    }
  }
}

#Preview {
  SelectRoleView(selectedRole: nil) { _ in
    //
  } didRoleSubmit: {
    //
  }
}
