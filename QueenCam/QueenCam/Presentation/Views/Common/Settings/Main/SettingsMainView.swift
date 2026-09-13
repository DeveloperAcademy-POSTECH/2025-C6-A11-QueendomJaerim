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
  let highlight: SettingsHighlight?
  private let cameraSettingsService: CameraSettingsServiceProtocol

  @State private var safariSheetItem: SafariSheetItem?
  @State private var settings: SettingsState

  /// 강조 표시를 끝냈는지 여부
  @State private var isHighlightFinished = false

  // MARK: - URLs
  var vocPageURL: URL? {
    guard let urlString = Bundle.main.infoDictionary?["VOCPageURL"] as? String else {
      return nil
    }
    return URL(string: urlString)
  }
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
    highlight: SettingsHighlight? = nil,
    cameraSettingsService: CameraSettingsServiceProtocol = DependencyContainer.defaultContainer.cameraSettingServcice
  ) {
    self.navigationRouter = navigationRouter
    self.role = role
    self.highlight = highlight
    self.cameraSettingsService = cameraSettingsService
    self._settings = State(
      initialValue: SettingsState(
        saveGuidingOverlayImageOn: cameraSettingsService.saveGuidingOverlayImageOn
      )
    )
  }
}

extension SettingsMainView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        SettingSection(title: "실험실") {
          SettingToggleSectionItem(
            title: "사진에 펜 가이드 함께 저장",
            supplementaryText: "촬영자 기준으로 적용되는 설정이에요",
            isHighlight: isHighlight(.saveGuidingOverlayImage),
            isOn: $settings.saveGuidingOverlayImageOn
          )
        }
        .padding(.leading, 20)
        .padding(.trailing, 26)

        SettingSection(title: "고객센터") {
          SettingSectionItem {
            finishHighlight()
            navigationRouter.push(.settings(.faq))
          }
            .title("자주하는 질문")

          SettingSectionItem {
            finishHighlight()
            openURL(for: vocPageURL, showInApp: false)
          }
          .title("의견 보내기")
        }
        .padding(.horizontal, 20)

        SettingSection(title: "정보") {
          SettingSectionItem {
            finishHighlight()
            openURL(for: privacyPageURL, showInApp: true)
          }
          .title("서비스 이용약관")

          SettingSectionItem {}
            .title("버전 정보")
            .supplementayText(LocalizedStringKey(stringLiteral: appVersion))
            .disabled(true)
        }
        .padding(.horizontal, 20)

        Text("© 2025-2026. 팀 퀸덤. 문승찬, 신지현, 엄태형, 윤보라, 이재림, 임영택, 차정인.")
          .font(.pretendard(.medium, size: 11))
          .foregroundStyle(.gray900)
          .padding(.top, 18)
          .padding(.horizontal, 20)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .onChange(of: settings.saveGuidingOverlayImageOn) { _, _ in
      finishHighlight()
    }
    .trackScreen(.settings, Self.self)
    .navigationTitle("설정")
    .navigationBarTitleDisplayMode(.inline)
    .fullScreenCover(item: $safariSheetItem) { sheetItem in
      SFSafariView(url: sheetItem.url)
        .ignoresSafeArea()
    }
    .onChange(of: settings) { previousSettings, newSettings in
      persist(newSettings)
      analyticsChanges(from: previousSettings, to: newSettings).forEach { change in
        AnalyticsService.sendEvent(.settingsChanged(change))
      }
    }
  }
}

extension SettingsMainView {
  /// 해당 항목을 지금 강조해야 하는지 여부
  ///
  /// 강조를 요청받고 진입한 경우에만 켜지며, 사용자가 그 설정을 조작하거나
  /// 화면을 벗어나면 꺼진다.
  /// 강조를 끝낸다
  ///
  /// 사용자가 설정을 바꾸거나 이 화면을 떠나는 동작을 하면 안내는 역할을 다한 것으로 본다.
  private func finishHighlight() {
    guard !isHighlightFinished else { return }

    withAnimation(.easeOut(duration: 0.3)) {
      isHighlightFinished = true
    }
  }

  private func isHighlight(_ target: SettingsHighlight) -> Bool {
    highlight == target && !isHighlightFinished
  }

  private func persist(_ settings: SettingsState) {
    cameraSettingsService.saveGuidingOverlayImageOn = settings.saveGuidingOverlayImageOn
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

#Preview {
  SettingsMainView(navigationRouter: NavigationRouter(), role: .model)
}
