//
//  ReferenceView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//  Reference가 Open일때와 Close일때의 View, CameraPreview에 주입할 예정

import SwiftUI

/// 레퍼런스 뷰 - 레퍼런스를 표시한다.
struct ReferenceView: View {
  var referenceViewModel: ReferenceViewModel
  @Binding var isLarge: Bool
  private let containerName = "ReferenceViewContainer"
  private var closeViewPadding: CGFloat {
    referenceViewModel.referenceHeight / 2 - 50.5
  }
  private var referenceToastPadding: CGFloat {
    referenceViewModel.hasReferenceToast ? 48 : 0
  }

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: referenceViewModel.alignment) {
        Color.clear
        Group {
          switch referenceViewModel.state {
          case .open:  // 레퍼런스 On
            OpenView(referenceViewModel: referenceViewModel, isLarge: $isLarge)
              .offset(referenceViewModel.dragOffset)
              .transition(.scale)
              .highPriorityGesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .named(containerName))
                  .onChanged { value in
                    referenceViewModel.dragChanged(value)
                  }
                  .onEnded { value in
                    // fold/unfold 접힘 판정
                    if !isLarge {
                      referenceViewModel.dragEnded()
                    }
                    // corner 위치 이동 판정
                    referenceViewModel.updateLocation(end: value.predictedEndLocation, size: geo.size, isLarge: isLarge)
                  }
              )
          case .close:  // 레퍼런스 Off
            Button {
              referenceViewModel.unFold()
            } label: {
              CloseView(referenceViewModel: referenceViewModel)
            }
            .transition(.scale)
            .padding(.horizontal, -8)
            .padding(.vertical, closeViewPadding)
            .highPriorityGesture(
              DragGesture(minimumDistance: 5, coordinateSpace: .named(containerName))
                .onChanged { value in
                  referenceViewModel.dragChanged(value)
                }
                .onEnded { _ in
                  referenceViewModel.dragEnded()
                }
            )

          case .delete:  // 레퍼런스 삭제
            EmptyView()
          }
        }
      }
    }
    .padding(.top, referenceToastPadding)
    .coordinateSpace(name: containerName)
  }
}
