//
//  StateToast.swift
//  QueenCam
//
//  Created by 임영택 on 10/31/25.
//

import SwiftUI

struct StateToast: View {
  let message: LocalizedStringKey
  let isImportant: Bool

  private let importantStateTintColor = Color(red: 254 / 255, green: 188 / 255, blue: 47 / 255)

  var body: some View {
    Text(message)
      .typo(.r12)
      .foregroundStyle(.black)
      .padding(.vertical, 8)
      .padding(.horizontal, 16)
      .glassEffect(isImportant ? .clear.tint(importantStateTintColor) : .clear.tint(.offWhite.opacity(0.6)))
  }
}

#Preview {
  struct StateToastPreviewContainer: View {
    @State private var isImportant: Bool = true
    @State private var imageID: UUID = UUID()

    var body: some View {
      ZStack {
        AsyncImage(url: URL(string: "https://picsum.photos/500"))
          .scaledToFit()
          .frame(maxWidth: 500, maxHeight: 500)
          .id(imageID)

        VStack {
          StateToast(message: "상태 라이팅 영역입니다.", isImportant: isImportant)
            .onTapGesture {
              isImportant.toggle()
            }

          Spacer()

          Button("이미지 새로 고침") {
            imageID = UUID()
          }
          .buttonStyle(.glassProminent)
        }
        .padding()
      }
      .frame(maxWidth: 500, maxHeight: 500)
    }
  }

  return StateToastPreviewContainer()
}
