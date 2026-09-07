import Foundation

@Observable
final class ReleaseNoteViewModel {
  private let onboardingSettingService: OnboardingSettingsServiceProtocol
  private let releaseNote: ReleaseNote

  init(
    onboardingSettingService: OnboardingSettingsServiceProtocol,
    releaseNote: ReleaseNote = .current
  ) {
    self.onboardingSettingService = onboardingSettingService
    self.releaseNote = releaseNote
  }
}

extension ReleaseNoteViewModel {

  // MARK: - Intents

  /// 지금 노출할 릴리즈 노트를 돌려준다
  ///
  /// 안내가 이미 배포된 버전의 것이고 아직 노출한 적이 없을 때만 돌려준다.
  func getReleaseNoteToShow() -> ReleaseNote? {
    let releaseNoteVersion = versionNumber(of: releaseNote)

    guard releaseNoteVersion <= VersionUtils.currentVersion,
      releaseNoteVersion > onboardingSettingService.lastShownReleaseNoteVersion
    else {
      return nil
    }

    return releaseNote
  }

  /// 노출을 마쳤음을 기록한다
  func releaseNoteDidFinish(_ releaseNote: ReleaseNote) {
    onboardingSettingService.lastShownReleaseNoteVersion = versionNumber(of: releaseNote)
  }

  private func versionNumber(of releaseNote: ReleaseNote) -> Int {
    VersionUtils.getVersionNumber(from: releaseNote.version)
  }
}
