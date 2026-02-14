//
//  SettingsView.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import SwiftUI

struct SettingsMainView {
  @Environment(\.dismiss) private var dismiss

  var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
  }
}

extension SettingsMainView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        SettingSection(title: "찍자 이용 가이드") {
          SettingBanner {
            //
          }
          .title("페어링 방법이 궁금하신가요?")
          .subtitle("새로운 친구를 등록하고 싶어요.")
          .image(.pairGuide)
        }
        .spacing(top: 16, titleToItem: 12, bottom: 20)
        .showSeparator(false)
        .padding(.horizontal, 20)

        HeaderSeparator()

        SettingSection(title: "고객지원") {
          SettingSectionItem {}
            .title("자주하는 질문")

          SettingSectionItem {}
            .title("의견 보내기")
        }
        .padding(.horizontal, 20)

        SettingSection(title: "정보") {
          SettingSectionItem {}
            .title("서비스 이용약관")

          SettingSectionItem {}
            .title("버전 정보")
            .supplementayText(appVersion)
            .disabled(true)
        }
        .padding(.horizontal, 20)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .navigationTitle("설정")
    .navigationBarTitleDisplayMode(.inline)
  }
}

extension SettingsMainView {
  private struct HeaderSeparator: View {
    var body: some View {
      Rectangle()
        .foregroundStyle(SettingsColors.headerSeparator)
        .frame(height: 6)
    }
  }
}

#Preview {
  SettingsMainView()
}
