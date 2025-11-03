//
//  LogExportingView.swift
//  QueenCam
//
//  Created by 임영택 on 11/2/25.
//

import SwiftUI

struct LogExportingView: View {
  @State private var sharingLogFile: SharingLogFile?

  var body: some View {
    VStack {
      Text("로그 내보내기")
        .font(.title)

      if let sharingLogFile {
        ShareLink(
          item: sharingLogFile,
          preview: .init(
            "로그 내보내기", image: Image(systemName: "text.page"), icon: Image(systemName: "text.page")
          )
        )
      } else {
        Text("로그 파일을 불러오고 있습니다.")
          .typo(.m13)
      }
    }
    .onAppear {
      sharingLogFile = SharingLogFile(
        url: QueenLogger.defaultLogFileURL,
        deviceInfo: .defaultValue
      )
    }
  }
}

#Preview {
  LogExportingView()
}
