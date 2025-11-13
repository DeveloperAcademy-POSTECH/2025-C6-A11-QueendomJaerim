import SwiftUI

/// 애니메이션에 사용할 값들을 정의하는 구조체
/// 프레임을 모두 표현하기 위함
struct KeyFrameAnimationStateValue {
  var scale: CGFloat = 1.0
  var degree: Double = 0.0
  var offsetX: CGFloat = 0.0
  var offsetY: CGFloat = 0.0
  var opacity: Double = 1.0
}

struct ThumbsUpView {
  @Binding var trigger: Bool

  // 30fps = 1프레임당 약 0.0333...초
  let frameDuration = 1.0 / 30.0
}

extension ThumbsUpView: View {
  var body: some View {
    Image("thumbs_up")
      .resizable()
      .frame(width: 100, height: 100)
      .keyframeAnimator(
        // 초기값 설정
        initialValue: KeyFrameAnimationStateValue(),
        // 애니메이션을 발동시킬 트리거
        trigger: trigger
      ) { view, values in
        // 계산된 값을 뷰에 적용
        view
          .scaleEffect(values.scale)
          .rotationEffect(.degrees(values.degree))
          .offset(x: values.offsetX, y: values.offsetY)
          .opacity(values.opacity)
      } keyframes: { _ in

        // --- 스케일 (Scale) 트랙 (14 frames) ---
        KeyframeTrack(\.scale) {
          LinearKeyframe(0.7, duration: frameDuration)
          LinearKeyframe(1.38, duration: frameDuration)
          LinearKeyframe(2.01, duration: frameDuration)
          LinearKeyframe(2.5, duration: frameDuration)
          LinearKeyframe(2.8, duration: frameDuration)
          LinearKeyframe(3.0, duration: frameDuration)
          LinearKeyframe(2.9, duration: frameDuration)
          LinearKeyframe(2.8, duration: frameDuration)
          LinearKeyframe(2.34, duration: frameDuration)
          LinearKeyframe(1.9, duration: frameDuration)
          LinearKeyframe(1.57, duration: frameDuration)
          LinearKeyframe(1.36, duration: frameDuration)
          LinearKeyframe(1.12, duration: frameDuration)
          LinearKeyframe(1.11, duration: frameDuration)
        }

        // --- 회전 (Degree) 트랙 (14 frames) ---
        KeyframeTrack(\.degree) {
          LinearKeyframe(23.0, duration: frameDuration)
          LinearKeyframe(16.0, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(-14.0, duration: frameDuration)
          LinearKeyframe(-26.0, duration: frameDuration)
          LinearKeyframe(-30.0, duration: frameDuration)
          LinearKeyframe(-25.0, duration: frameDuration)
          LinearKeyframe(-17.0, duration: frameDuration)
          LinearKeyframe(-10.0, duration: frameDuration)
          LinearKeyframe(-7.0, duration: frameDuration)
          LinearKeyframe(-4.0, duration: frameDuration)
          LinearKeyframe(12.0, duration: frameDuration)
          LinearKeyframe(26.0, duration: frameDuration)
          LinearKeyframe(26.0, duration: frameDuration)
        }

        // --- X축 이동 (OffsetX) 트랙 (14 frames) ---
        KeyframeTrack(\.offsetX) {
          LinearKeyframe(0.0, duration: frameDuration)
          LinearKeyframe(0.0, duration: frameDuration)
          LinearKeyframe(2.5, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(0.0, duration: frameDuration)
          LinearKeyframe(3.0, duration: frameDuration)
          LinearKeyframe(1.5, duration: frameDuration)
          LinearKeyframe(3.5, duration: frameDuration)
          LinearKeyframe(2.5, duration: frameDuration)
          LinearKeyframe(1.5, duration: frameDuration)
          LinearKeyframe(-3.0, duration: frameDuration)
          LinearKeyframe(-21.0, duration: frameDuration)
          LinearKeyframe(-14.0, duration: frameDuration)
          LinearKeyframe(6.0, duration: frameDuration)
        }

        // --- Y축 이동 (OffsetY) 트랙 (14 frames) ---
        KeyframeTrack(\.offsetY) {
          LinearKeyframe(0.0, duration: frameDuration)
          LinearKeyframe(-47.6, duration: frameDuration)
          LinearKeyframe(-100.0, duration: frameDuration)
          LinearKeyframe(-147.0, duration: frameDuration)
          LinearKeyframe(-178.0, duration: frameDuration)
          LinearKeyframe(-200.0, duration: frameDuration)
          LinearKeyframe(-213.0, duration: frameDuration)
          LinearKeyframe(-218.0, duration: frameDuration)
          LinearKeyframe(-215.0, duration: frameDuration)
          LinearKeyframe(-213.0, duration: frameDuration)
          LinearKeyframe(-167.0, duration: frameDuration)
          LinearKeyframe(-5.5, duration: frameDuration)
          LinearKeyframe(164.0, duration: frameDuration)
          LinearKeyframe(290.0, duration: frameDuration)
        }

        // --- 투명도 (Opacity) 트랙 (14 frames) ---
        KeyframeTrack(\.opacity) {
          LinearKeyframe(0.5, duration: frameDuration)
          LinearKeyframe(0.7, duration: frameDuration)
          LinearKeyframe(0.85, duration: frameDuration)
          LinearKeyframe(0.9, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
          LinearKeyframe(1.0, duration: frameDuration)
        }
      }
  }
}
