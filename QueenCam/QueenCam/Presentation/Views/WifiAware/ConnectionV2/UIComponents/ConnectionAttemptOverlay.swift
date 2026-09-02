import SwiftUI

struct ConnectionAttemptOverlay: View {
  let state: ConnectionAttemptState
  let stopAction: () -> Void
  let closeFailureAction: () -> Void

  var body: some View {
    if state != .idle {
      Color.black.opacity(0.8)
        .ignoresSafeArea()

      panel
        .padding(.horizontal, 41)
    }
  }

  @ViewBuilder
  private var panel: some View {
    switch state {
    case .idle:
      EmptyView()
    case .connecting(let deviceName):
      VStack(alignment: .leading, spacing: 0) {
        Text("‘\(deviceName)’(와)과\n연결 중이에요.")
          .typo(.sb17Line26)
          .foregroundStyle(.contentPrimary)

        Text("상대방 기기에서도 '연결' 버튼을 눌렀는지 확인해 주세요.")
          .typo(.m14Line22)
          .foregroundStyle(.gray400)
          .padding(.top, 8)

        ProgressView()
          .controlSize(.large)
          .tint(.gray400)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 24)

        Button("연결 중단하기", action: stopAction)
          .typo(.sb16)
          .foregroundStyle(.gray600)
          .frame(maxWidth: .infinity)
          .frame(height: 52)
          .background(Color(red: 0x33 / 255, green: 0x33 / 255, blue: 0x33 / 255), in: .capsule)
          .buttonStyle(.plain)
      }
      .padding(16)
      .background(.gray900, in: .rect(cornerRadius: 32))
    case .failed:
      VStack(alignment: .leading, spacing: 0) {
        Text("연결에 실패했어요.")
          .typo(.sb17Line26)
          .foregroundStyle(.contentPrimary)

        Text("상대방과 함께 다시 시도해 주세요.")
          .typo(.m14Line22)
          .foregroundStyle(.gray400)
          .padding(.top, 8)

        Button("닫기", action: closeFailureAction)
          .typo(.sb16)
          .foregroundStyle(.contentPrimary)
          .frame(maxWidth: .infinity)
          .frame(height: 52)
          .background(Color(red: 0x33 / 255, green: 0x33 / 255, blue: 0x33 / 255), in: .rect(cornerRadius: 12))
          .buttonStyle(.plain)
          .padding(.top, 24)
      }
      .padding(16)
      .background(.gray900, in: .rect(cornerRadius: 32))
    }
  }
}
