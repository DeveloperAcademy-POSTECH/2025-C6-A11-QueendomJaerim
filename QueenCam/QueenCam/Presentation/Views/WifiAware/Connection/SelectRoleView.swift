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
  let didRoleSubmit: (Role) -> Void

  let individualSymbolOffset: CGFloat = 7.5

  var symbolsContainerOffset: CGFloat {  // 선택 시 가운데 정렬
    if selectedRole == .model {
      return -80 + individualSymbolOffset
    } else if selectedRole == .photographer {
      return 80 - individualSymbolOffset
    } else {
      return .zero
    }
  }
}

extension SelectRoleView: View {
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack {
        Spacer()

        header

        Spacer()
          .frame(height: 38)

        roleSelectButtons

        Spacer()
          .frame(height: 38)

        roleDescriptions

        Spacer()

        Button {
          if let selectedRole {
            didRoleSubmit(selectedRole)
          }
        } label: {
          Text("기기 연결 시작")
            .font(.pretendard(.medium, size: 16))
            .foregroundColor(selectedRole == nil ? .gray : .white)
            .background(
              Capsule()
                .foregroundStyle(.clear)
            )
            .frame(maxWidth: .infinity, maxHeight: 52)
        }
        .glassEffect(.regular)
      }
      .animation(.linear, value: selectedRole)
      .padding(16)
    }
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button("닫기", systemImage: "chevron.left") {
          dismiss()
        }
      }
    }
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
  } didRoleSubmit: { _ in
    //
  }
}
