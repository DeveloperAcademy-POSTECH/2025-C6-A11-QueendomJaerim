import SwiftUI

extension PhotoDetailView {
  struct TopToolBarComponent {
    let currentIndex: Int
    let totalItemListCount: Int
    let isActive: Bool
    let onTapBackAction: () -> Void
    let onTapRegisterAction: () -> Void
  }
}

extension PhotoDetailView.TopToolBarComponent {

}

extension PhotoDetailView.TopToolBarComponent: View {
  var body: some View {
    VStack {  // TopToolbar + 백그라운드
      HStack {  // TopToolbar
        Button(action: { onTapBackAction() }) {
          Image(systemName: "chevron.left")
            .font(Font.custom("SF Pro", size: 17))
            .fontWeight(.medium)
            .foregroundStyle(.offWhite)
            .frame(width: 44, height: 44)
            .glassEffect(.clear, in: .circle)
        }

        Spacer()

        Button(action: { onTapRegisterAction() }) {
          Text("등록")
            .font(Font.custom("SF Pro", size: 15))
            .foregroundStyle(isActive ? .offWhite : .disabled)
            .frame(width: 60, height: 40)
            .glassEffect(.clear, in: .capsule)
        }
        .disabled(!isActive)
      }
      .overlay(alignment: .center) {
        VStack(alignment: .center, spacing: .zero) {
          Text("Photos")
            .typo(.sfSB15)
            .foregroundStyle(.white)

          Text("\(currentIndex + 1) / \(totalItemListCount)")
            .typo(.sfM12)
            .foregroundStyle(Color.LabelsVibrantSecondary)
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 16)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 120, alignment: .bottom)
    .blur(radius: 0)
    .safeAreaPadding(.top, 16)
    .glassEffect(.clear.tint(.black), in: .rect)
  }
}

#Preview {
  ScrollView {

  }
  .background(.black)
  .overlay(alignment: .top) {
    VStack {
      PhotoDetailView.TopToolBarComponent(
        currentIndex: 3,
        totalItemListCount: 6,
        isActive: false,
        onTapBackAction: {},
        onTapRegisterAction: {}
      )

      HStack {
        PhotoDetailView.LiveIconComponent(isLivePhoto: true)

        Spacer()

        CheckCircleButton(
          isSelected: true,
          role: .photographer,
          isLarge: true,
          didTap: {}
        )
        .padding(.top, 16)
        .padding(.trailing, 18)

      }
    }
    .ignoresSafeArea()
  }
}

extension Color {

  // 등록 활성화 및 백
  static let LabelsVibrantControlsPrimary: Color = Color(red: 0.25, green: 0.25, blue: 0.25)

  // 사진 수 및 인덱스
  static let LabelsVibrantSecondary: Color = Color(red: 0.6, green: 0.6, blue: 0.6)

  // 등록 disabled
  static let LabelsVibrantControlsTertiary: Color = Color(red: 0.85, green: 0.85, blue: 0.85)
}
