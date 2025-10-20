//
//  ReferenceView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//  Reference가 Open일때와 Close일때의 View, CameraPreview에 주입할 예정

import SwiftUI

enum ReferenceState: Equatable {
  case open  // Reference(PiP) 모드 활성화
  case close  // Reference(PiP) 모두 비활성화
  case delete  // Reference(PiP) 삭제
}

struct ReferenceView: View {
  @Bindable var referenceViewModel: ReferenceViewModel
  // 레퍼런스 임시 배치 위치 => 스프린트2,3에 수정 예정
  var top: CGFloat = 8
  var leading: CGFloat = 0
  let role: Role?
  var body: some View {
    Group {
      switch referenceViewModel.state {
      case .open:  // 레퍼런스 On
        OpenView(referenceViewModel: referenceViewModel, role: role)
          .padding(.top, top)
          .padding(.leading, leading)
          .offset(referenceViewModel.dragOffset)
          .highPriorityGesture(
            DragGesture(minimumDistance: 5)
              .onChanged {
                referenceViewModel.dragChanged($0)
              }
              .onEnded { _ in
                referenceViewModel.dragEnded()
              }
          )
      case .close:  // 레퍼런스 Off
        Button {
          referenceViewModel.unFold()
        } label: {
          CloseView()
            .padding(.top, top)
            .padding(.leading, -8 )
        }
      case .delete:  // 레퍼런스 삭제
        EmptyView()
      }
    }

  }
}
