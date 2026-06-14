//
//  SettingsView.swift
//  QueenCam
//
//  Created by 임영택 on 2/14/26.
//

import SwiftUI

struct SettingsMainView {
  let navigationRouter: NavigationRouter
  let role: Role?
  private let cameraSettingsService: CameraSettingsServiceProtocol

  @State private var safariSheetItem: SafariSheetItem?
  @State private var guideSheetItem: GuideSheetItem?
  @State private var isConfirmingRole = false
  @State private var savePenOverlayImageOn: Bool

  // MARK: - URLs
  let vocPageURL = URL(
    string: "https://docs.google.com/forms/d/e/1FAIpQLSc0GRoJYU8a-Ki5PmEDIv7GmBRtJ0PNG-zh-YsM5i1FzCWkJg/viewform?usp=header"
  )
  let privacyPageURL = URL(
    string: "https://cyan-zydeco-5e9.notion.site/ZZikZZa-2025-11-13-2aa1b6b29f2c80cf90eed7ca2afc0e32?pvs=73"
  )

  // MARK: - Computed
  var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
  }

  init(
    navigationRouter: NavigationRouter,
    role: Role?,
    cameraSettingsService: CameraSettingsServiceProtocol = DependencyContainer.defaultContainer.cameraSettingServcice
  ) {
    self.navigationRouter = navigationRouter
    self.role = role
    self.cameraSettingsService = cameraSettingsService
    _savePenOverlayImageOn = State(initialValue: cameraSettingsService.savePenOverlayImageOn)
  }
}

extension SettingsMainView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        SettingSection(title: "찍자 이용 가이드") {
          SettingBanner {
            if let role {
              guideSheetItem = GuideSheetItem(role: role)
            } else {
              isConfirmingRole.toggle()
            }
          }
          .title("페어링 방법이 궁금하신가요?")
          .subtitle("새로운 친구를 등록하고 싶어요.")
          .image(.pairGuide)
        }
        .spacing(top: 16, titleToItem: 12, bottom: 20)
        .showSeparator(false)
        .padding(.horizontal, 20)

        HeaderSeparator()

        SettingSection(title: "촬영") {
          SettingToggleSectionItem(title: "펜 가이드 함께 저장", isOn: $savePenOverlayImageOn)
        }
        .padding(.horizontal, 20)

        SettingSection(title: "고객센터") {
          SettingSectionItem {
            navigationRouter.push(.settings(.faq))
          }
            .title("자주하는 질문")

          SettingSectionItem {
            openURL(for: vocPageURL, showInApp: false)
          }
          .title("의견 보내기")
        }
        .padding(.horizontal, 20)

        SettingSection(title: "정보") {
          SettingSectionItem {
            openURL(for: privacyPageURL, showInApp: true)
          }
          .title("서비스 이용약관")

          SettingSectionItem {}
            .title("버전 정보")
            .supplementayText(LocalizedStringKey(stringLiteral: appVersion))
            .disabled(true)
        }
        .padding(.horizontal, 20)

        Text("© 2025. 팀 퀸덤. 문승찬, 엄태형, 윤보라, 이재림, 임영택, 차정인.")
          .font(.pretendard(.medium, size: 11))
          .foregroundStyle(.gray900)
          .padding(.top, 18)
          .padding(.horizontal, 20)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .navigationTitle("설정")
    .navigationBarTitleDisplayMode(.inline)
    .fullScreenCover(item: $safariSheetItem) { sheetItem in
      SFSafariView(url: sheetItem.url)
        .ignoresSafeArea()
    }
    .fullScreenCover(item: $guideSheetItem) { sheetItem in
      NavigationStack {
        ConnectionGuideView(role: sheetItem.role, referer: .settings) {
          guideSheetItem = nil
        } backButtonDidTap: {
          guideSheetItem = nil
        }
      }
    }
    .confirmationDialog("", isPresented: $isConfirmingRole) {
      Button("작가 가이드") {
        guideSheetItem = GuideSheetItem(role: .photographer)
      }
      Button("모델 가이드") {
        guideSheetItem = GuideSheetItem(role: .model)
      }
      Button("취소", role: .cancel) {}
    }
    .onChange(of: savePenOverlayImageOn) { _, newValue in
      cameraSettingsService.savePenOverlayImageOn = newValue
    }
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

extension SettingsMainView {
  func openURL(for url: URL?, showInApp: Bool) {
    if let url {
      if showInApp {
        safariSheetItem = SafariSheetItem(url: url)
      } else {
        UIApplication.shared.open(url)
      }
    } else {
      QueenLogger(category: "SettingsMainView")
        .error("URL is nil")
    }
  }
}

private struct SafariSheetItem: Identifiable {
  let url: URL
  var id: String {
    url.absoluteString
  }
}

private struct GuideSheetItem: Identifiable {
  let role: Role
  var id: String {
    role.displayName
  }
}

#Preview {
  SettingsMainView(navigationRouter: NavigationRouter(), role: .model)
}
