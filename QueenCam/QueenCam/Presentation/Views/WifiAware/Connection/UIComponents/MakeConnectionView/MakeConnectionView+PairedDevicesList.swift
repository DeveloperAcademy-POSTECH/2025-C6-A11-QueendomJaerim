//
//  MakeConnectionView+PairedDevicesList.swift
//  QueenCam
//
//  Created by 임영택 on 11/5/25.
//

import SwiftUI
import WiFiAware

extension MakeConnectionView {
  struct PairedDevicesList {
    let pairedDevices: [ExtendedWAPairedDevice]
    let isPairing: Bool
    let isConnected: Bool
    /// 특정 디바이스가 선택된 디바이스인지 여부를 반환하는 클로져.. true를 반환하면 프로그레스 뷰를 해당 디바이스 옆에 띄운다.
    let selectedDevice: WAPairedDevice?
    let connectButtonDidTap: (WAPairedDevice) -> Void

    // MARK: Colors
    let titleLabelForegroundColor = Color(red: 0xD4 / 255, green: 0xD4 / 255, blue: 0xD4 / 255)
    let checkmarkBackgroundColor = Color(red: 0x27 / 255, green: 0xC8 / 255, blue: 0x40 / 255)
    let dividerColor = Color.gray900

    // MARK: Constants
    // 디바이스 수에 따라 UI가 바뀜. 바뀌는 기준 정의
    // 반드시 devicesCountsThreshold1 < devicesCountsThreshold2를 만족
    let devicesCountsThreshold1: Int = 2
    let devicesCountsThreshold2: Int = 4

    // MARK: State
    @State private var isCheckMarkAnimating: Bool = true
  }
}

extension MakeConnectionView.PairedDevicesList: View {
  var body: some View {
    VStack(spacing: 0) {
      // 타이틀
      HStack {
        Text("등록된 친구")
          .foregroundStyle(titleLabelForegroundColor)
          .font(.pretendard(.semibold, size: 15))

        Spacer()
      }

      Rectangle()
        .foregroundStyle(dividerColor)
        .frame(height: 0.5)
        .padding(.top, 8.5)
        .padding(.bottom, 8)

      GeometryReader { geometry in  // Spacer를 사용하기 위해 크기를 알아야 함
        ScrollView(showsIndicators: false) {
          HStack {  // 디바이스 전체 너비 스크롤
            Spacer()
          }

          VStack {
            // MARK: 페어링 기기 리스트
            VStack(spacing: 16) {
              ForEach(pairedDevices) { device in
                pairedDeviceRowView(for: device)
              }
            }
            .padding(.leading, 4)
            .padding(.trailing, 2)

            // 페어링 기기 수 조건에 따라 앞 혹은 뒤에 Spacer
            if pairedDevices.count < devicesCountsThreshold2 {
              Spacer()
            }

            // MARK: 안내 메시지
            switch pairedDevices.count {
            case 0..<devicesCountsThreshold1:
              guidingMessageView
                .padding(.bottom, 300)
            case devicesCountsThreshold1..<devicesCountsThreshold2:
              guidingMessageView
                .padding(.bottom, 240)
            case devicesCountsThreshold2...:
              guidingMessageView
                .padding(.top, 60)
            default:  // should not reach
              Text("잘못된 범위")
            }

            if pairedDevices.count >= devicesCountsThreshold2 {
              Spacer()
            }
          }
          .frame(minHeight: geometry.size.height)
        }
      }
    }
    .onChange(of: isConnected) { _, newValue in
      if newValue {
        isCheckMarkAnimating.toggle()  // 체크마크 애니메이션 시작
      }
    }
  }

  var guidingMessageView: some View {
    Text("친구와 연결하기 위해 먼저\n‘주변 기기 찾기’를 통해 친구를 등록해주세요.")
      .multilineTextAlignment(.center)
      .typo(.m15)
      .foregroundStyle(.gray600)
  }

  var connectCompleteSymbol: some View {
    Image(systemName: "checkmark")
      .resizable()
      .renderingMode(.template)
      .foregroundStyle(.originalWhite)
      .symbolEffect(.drawOn, isActive: isCheckMarkAnimating)
      .scaledToFit()
      .frame(width: 13)
      .background(
        Circle()
          .foregroundStyle(checkmarkBackgroundColor)
          .frame(width: 29, height: 29)
      )
  }

  func pairedDeviceRowView(for deviceInfo: ExtendedWAPairedDevice) -> some View {
    let controlsContainerWidth: CGFloat = LocaleUtils.currentLocale == .korean ? 57 : 100
    let controlsContainerHeight: CGFloat = 33

    return HStack(alignment: .center) {
      Text(deviceInfo.device.pairingInfo?.pairingName ?? "알 수 없는 이름")
        .typo(.m18)
        .foregroundStyle(.offWhite)

      Text(deviceInfo.lastConnectedAt?.formatted(date: .numeric, time: .shortened) ?? "")
        .typo(.m18)
        .foregroundStyle(.offWhite)

      Spacer()

      // 프로그레스 뷰 + 연결 버튼
      VStack(alignment: .center, spacing: 0) {  // 정렬을 위한 컨테이너
        if deviceInfo.device == selectedDevice {
          if isConnected {
            connectCompleteSymbol
          }

          if isPairing && !isConnected {  // host의 경우 연결중과 연결완료가 구분되지 않으므로 조건을 더 한정
            ProgressView()
              .tint(.offWhite)
              .frame(width: controlsContainerHeight, height: controlsContainerHeight)
          }
        } else {
          Button {
            connectButtonDidTap(deviceInfo.device)
          } label: {
            Text("연결")
              .typo(.m14)
              .foregroundStyle(.offWhite)
              .padding(.vertical, 6)
              .padding(.horizontal, 16)
          }
          .glassEffect(.regular)
        }
      }
      .frame(width: controlsContainerWidth, height: controlsContainerHeight)
    }
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()

    MakeConnectionView.PairedDevicesList(
      pairedDevices: [
        .init(device: createTestDevice(id: 0, name: "임영폰")!, lastConnectedAt: Date()),
        .init(device: createTestDevice(id: 1, name: "루크폰")!, lastConnectedAt: nil),
        .init(device: createTestDevice(id: 2, name: "보타폰")!, lastConnectedAt: nil),
        .init(device: createTestDevice(id: 3, name: "요시폰")!, lastConnectedAt: nil),
        .init(device: createTestDevice(id: 4, name: "페퍼폰")!, lastConnectedAt: nil),
        .init(device: createTestDevice(id: 5, name: "차차폰")!, lastConnectedAt: nil),
        .init(device: createTestDevice(id: 6, name: "섭섭폰")!, lastConnectedAt: nil),
        .init(device: createTestDevice(id: 7, name: "하워드폰")!, lastConnectedAt: nil)
      ],
      isPairing: false,
      isConnected: false,
      selectedDevice: nil
    ) { _ in }
  }
}

/// 프리뷰를 위한 테스트 데이터 팩토리
private func createTestDevice(id: Int, name: String) -> WAPairedDevice? {
  // 테스트할 WAPairedDevice의 JSON 형태를 문자열로 정의합니다.
  let deviceJSON =
    """
    {
      "id": \(id),
      "name": "\(name)",
      "pairingInfo": {
        "pairingName": "\(name)",
        "vendorName": "QueenDom",
        "modelName": "TestModel-001"
      }
    }
    """

  // JSON 문자열을 Data로 변환
  if let jsonData = deviceJSON.data(using: .utf8) {
    do {
      return try JSONDecoder().decode(WAPairedDevice.self, from: jsonData)
    } catch {
      // swiftlint:disable:next no_print_in_production
      print("디코딩 실패: \(error)")
    }
  }

  return nil
}

#Preview("DrawOn Animation") {
  struct AnimationPreviewContainer: View {
    @State var isAnimating: Bool = true

    var body: some View {
      VStack {
        Button("애니메이션 토글") {
          isAnimating.toggle()
        }

        Text("isAnimating: \(isAnimating ? "true" : "false")")

        Image(systemName: "checkmark")
          .resizable()
          .renderingMode(.template)
          .foregroundStyle(.originalWhite)
          .symbolEffect(.drawOn, isActive: isAnimating)
          .scaledToFit()
          .frame(width: 13)
          .background(
            Circle()
              .foregroundStyle(
                Color(red: 0x27 / 255, green: 0xC8 / 255, blue: 0x40 / 255)
              )
              .frame(width: 29, height: 29)
          )
      }
    }
  }

  return AnimationPreviewContainer()
}
