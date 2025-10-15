//
//  ReferenceView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//  Reference가 Open일때와 Close일때의 View, CameraPreview에 주입할 예정

enum ReferanceState: Equatable {
  case open // Reference(PiP) 모드 활성화
  case close // Reference(PiP) 모두 비활성화
  case delete // Reference(PiP) 삭제
}

import SwiftUI

struct ReferenceView: View {
  @StateObject private var viewModel = ReferenceViewModel()
  // 레퍼런스 임시 배치 위치 => 스프린트2,3에 수정 예정
  var top: CGFloat = 24
  var leading: CGFloat = 4
  let role: Role?
  var body: some View {
    Group {
      switch viewModel.state {
      case .open:
        OpenView(viewModel: viewModel, role: role )
          .padding(.top, top)
          .padding(.leading, leading)
          .offset(viewModel.dragOffset)
          .highPriorityGesture(
            DragGesture(minimumDistance: 5)
              .onChanged {
                viewModel.dragChanged($0)
              }
              .onEnded { _ in
                viewModel.dragEnded()
              }
          )
      case .close:
        Button {
          viewModel.unFold()
        } label: {
          CloseView()
            .padding(.top, top)
        }
      case .delete:
        EmptyView()
      }
    }
    
  }
}

#Preview {
  ReferenceView(role: .photographer)
}
