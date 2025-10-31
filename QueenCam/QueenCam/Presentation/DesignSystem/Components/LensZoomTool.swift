import SwiftUI

struct LensZoomTool {
  let zoomScaleItemList: [CGFloat]
  let currentZoomFactor: CGFloat
  let activeZoom: CGFloat
  let onZoomChange: (CGFloat) -> Void
}

extension LensZoomTool {

  // 선택된 배율을 가운데로 이동시키는 offset 계산
  private func getCenterOffset() -> CGFloat {
    guard let activeIndex = zoomScaleItemList.firstIndex(of: activeZoom) else {
      return 0
    }

    let itemWidth: CGFloat = 52
    let spacing: CGFloat = 20
    let totalWidth = itemWidth + spacing
    let centerIndex = CGFloat(zoomScaleItemList.count - 1) / 2.0
    return (centerIndex - CGFloat(activeIndex)) * totalWidth
  }
}

extension LensZoomTool: View {

  var body: some View {
    HStack(alignment: .center, spacing: 14) {
      ForEach(zoomScaleItemList, id: \.self) { item in
        Button(action: { onZoomChange(item) }) {
          Circle()
            .fill(item == activeZoom ? .black.opacity(0.6) : .clear)
            .frame(width: 38, height: 38)
            .overlay {
              Text(displayText(for: item))
                .font(.system(size: 15))
                .foregroundStyle(item == activeZoom ? Color.MiscellaneousWindowControlsMinimize : .offWhite)
            }
            .animation(nil, value: currentZoomFactor)
        }
      }
    }
    .offset(x: getCenterOffset())
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: activeZoom)
  }

  //  핀치 vs 프리셋 구분 로직
  private func displayText(for item: CGFloat) -> String {
    let isActive = item == activeZoom
    let isPinching = abs(currentZoomFactor - activeZoom) > 0.05

    if isActive {
      if isPinching {
        return String(format: "%.1fx", currentZoomFactor)
      } else {
        return item == floor(item)
          ? String(format: "%.0fx", item)
          : String(format: "%.1fx", item)
      }
    } else {
      return item == floor(item)
        ? String(format: "%.0f", item)
        : String(format: "%.1f", item).replacingOccurrences(of: "0", with: "")
    }
  }
}

#Preview {
  ZStack {
    Color.gray.ignoresSafeArea()
    LensZoomTool(
      zoomScaleItemList: [0.5, 1, 2],
      currentZoomFactor: 1.23,
      activeZoom: 1.0,
      onZoomChange: { _ in }
    )
  }
}

extension Color {
  static let MiscellaneousWindowControlsMinimize = Color(red: 1, green: 0.74, blue: 0.18)
}
