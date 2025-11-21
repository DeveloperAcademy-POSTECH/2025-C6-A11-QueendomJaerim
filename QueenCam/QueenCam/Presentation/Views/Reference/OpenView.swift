//
//  OpenView.swift
//  QueenCam
//
//  Created by 윤보라 on 10/14/25.
//
//  Camera Preview에서 제시되는 레퍼런스 사진 View

import SwiftUI

struct OpenView: View {
  var referenceViewModel: ReferenceViewModel
  @State private var showDelete: Bool = false
  @State private var showDeleteConfirmAlert: Bool = false
  @Binding var isLarge: Bool
  private let enlargeDuration: Double = 0.25
  private let shrinkDuration: Double = 0.25

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Group {
        if let image = referenceViewModel.image {
          let ratio = ReferenceSize.referenceRatio(width: image.size.width, height: image.size.height)
          /// 원본 이미지의 비율(높이/너비)
          let aspect = image.size.height / image.size.width
          let baseWidth = ratio.width
          /// 레퍼런스의 최종 너비
          let width = isLarge ? baseWidth * 2 : baseWidth
          let baseHeight = baseWidth * aspect
          /// 레퍼런스의 최종 높이
          let height: CGFloat = {
            switch ratio {
            case .ratio16x9:
              return isLarge ? 160 * 2 : 160
            case .ratio9x16:
              return isLarge ? 90 * 2 : 90
            default:
              return isLarge ? baseHeight * 2 : baseHeight
            }
          }()
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height, alignment: .center)
            .onAppear { referenceViewModel.referenceHeight = height }
            .glassEffect(.clear, in: .rect(cornerRadius: 24))
            .clipShape(.rect(cornerRadius: 24))
            .onTapGesture {
              withAnimation(.easeInOut(duration: !isLarge ? enlargeDuration : shrinkDuration)) {
                isLarge.toggle()
              }
            }
        }
      }

      if showDelete && (referenceViewModel.image != nil) {
        // 레퍼런스 삭제 버튼
        Button {
          showDeleteConfirmAlert = true
        } label: {
          ReferenceDeleteButton()
            .scaleEffect(showDelete ? 1.0 : 0.5)
            .opacity(showDelete ? 1.0 : 0.0)
        }
        .padding(12)
        .transition(.opacity.combined(with: .scale))
      }
    }
    .onChange(of: isLarge) { _, newValue in
      if newValue {
        DispatchQueue.main.asyncAfter(deadline: .now() + enlargeDuration * 0.6) {
          withAnimation(.easeOut(duration: 0.09)) {
            guard isLarge else { return }
            showDelete = true
          }
        }
      } else {
        showDelete = false
      }
    }
    .alert(
      "참고 이미지를 삭제합니다.",
      isPresented: $showDeleteConfirmAlert,
      actions: {
        Button(role: .destructive) {
          deleteReferenceConfirmButtonDidTap()
        } label: {
          Text("삭제")
        }

        Button(role: .cancel) {
        } label: {
          Text("취소")
        }
      },
      message: {
        Text("친구의 기기에 올라간 참고 이미지도 함께 삭제됩니다.")
      }
    )
  }
}

extension OpenView {

  // MARK: - User Intents

  private func deleteReferenceConfirmButtonDidTap() {
    referenceViewModel.onDelete()
    showDelete = false
    isLarge = false
  }
}
