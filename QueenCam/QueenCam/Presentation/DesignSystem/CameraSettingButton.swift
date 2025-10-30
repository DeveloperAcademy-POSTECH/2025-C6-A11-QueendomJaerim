import SwiftUI

struct CameraSettingButton {
  let title: String
  let systemName: String
  let isActive: Bool
  let tapAction: () -> Void
}

extension CameraSettingButton: View {
  var body: some View {
    VStack(alignment: .center, spacing: 8) {
      Button(action: { tapAction() }) {
        Circle()
          .fill(.black.opacity(0.5))
          .frame(width: 69, height: 69)
          .overlay {
            Image(systemName: systemName)
              .font(.system(size: 28))
              .foregroundStyle(isActive ? .photographerPrimary : .offWhite)
          }
      }

      Text(title)
        .typo(.sfRoundedR15)
        .foregroundStyle(.offWhite)
        .multilineTextAlignment(.center)
    }
  }
}

#Preview {
  VStack(spacing: 30) {

    HStack {
      CameraSettingButton(title: "LIVE", systemName: "livephoto.slash", isActive: false, tapAction: {})

      CameraSettingButton(title: "LIVE", systemName: "livephoto", isActive: true, tapAction: {})

      CameraSettingButton(title: "LIVE", systemName: "livephoto.badge.automatic", isActive: true, tapAction: {})
    }

    HStack {

      CameraSettingButton(title: "플래시", systemName: "bolt.slash", isActive: false, tapAction: {})

      CameraSettingButton(title: "플래시", systemName: "bolt.fill", isActive: true, tapAction: {})

      CameraSettingButton(title: "플래시", systemName: "bolt.badge.automatic.fill", isActive: true, tapAction: {})
    }

    HStack {

      CameraSettingButton(title: "그리드", systemName: "grid", isActive: false, tapAction: {})

      CameraSettingButton(title: "그리드", systemName: "grid", isActive: true, tapAction: {})
    }
  }

  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(.gray)
}
