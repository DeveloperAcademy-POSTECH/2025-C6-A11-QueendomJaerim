//
//  ReferenceView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//  Reference가 Open일때와 Close일때의 View, CameraPreview에 주입할 예정

import SwiftUI

/// 레퍼런스 뷰 - 레퍼런스를 표시한다.
struct ReferenceView: View {
  @Bindable var referenceViewModel: ReferenceViewModel
  @Binding var isLarge: Bool
  // FIXME: 레퍼런스 임시 배치 위치 => 스프린트2,3에 수정 예정
  var top: CGFloat = 8
  var leading: CGFloat = 0
  let role: Role?
  private let containerName = "ReferenceViewContainer"

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: referenceViewModel.alignment) {
        Color.clear
        Group {
          switch referenceViewModel.state {
          case .open:  // 레퍼런스 On
            OpenView(referenceViewModel: referenceViewModel, isLarge: $isLarge, role: role)
              .offset(referenceViewModel.dragOffset)
              .highPriorityGesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .named(containerName))
                  .onChanged { value in
                    referenceViewModel.dragChanged(value)
                  }
                  .onEnded { value in
                    // fold/unfold 접힘 판정
                    referenceViewModel.dragEnded()
                    // corner 위치 이동 판정
                    referenceViewModel.updateLocation(end: value.predictedEndLocation, size: geo.size)
                  }
              )

          case .close:  // 레퍼런스 Off
            Button {
              referenceViewModel.unFold()
            } label: {
              CloseView()
            }

          case .delete:  // 레퍼런스 삭제
            EmptyView()
          }
        }
      }
    }.coordinateSpace(name: containerName)
  }
}
