import Foundation

@Observable
final class ReleaseNoteViewModel {
  private let onboardingSettingService: OnboardingSettingsServiceProtocol

  /// 이 앱 버전이 가지고 있는 안내 정의
  private let currentReleaseNote: ReleaseNote

  /// 노출 중인 릴리즈 노트
  private(set) var releaseNoteItem: ReleaseNote?

  init(
    onboardingSettingService: OnboardingSettingsServiceProtocol,
    currentReleaseNote: ReleaseNote = .current
  ) {
    self.onboardingSettingService = onboardingSettingService
    self.currentReleaseNote = currentReleaseNote
  }
}

extension ReleaseNoteViewModel {

  /// 노출 조건을 따져보고 만족하면 릴리즈 노트를 띄운다
  /// 안내가 이미 배포된 버전의 것이고 아직 노출한 적이 없을 때만 띄운다.
  /// 조건을 만족하지 않으면 현재 노출 상태를 건드리지 않는다.
  func checkReleaseNote() {
    let releaseNoteVersion = versionNumber(of: currentReleaseNote)

    guard releaseNoteVersion <= VersionUtils.currentVersion,
      releaseNoteVersion > onboardingSettingService.lastShownReleaseNoteVersion
    else { return }

    releaseNoteItem = currentReleaseNote
  }

  func closeReleaseNote() {
    guard let releaseNoteItem else { return }

    onboardingSettingService.lastShownReleaseNoteVersion = versionNumber(of: releaseNoteItem)
    self.releaseNoteItem = nil
  }

  private func versionNumber(of releaseNote: ReleaseNote) -> Int {
    VersionUtils.getVersionNumber(from: releaseNote.version)
  }
}
