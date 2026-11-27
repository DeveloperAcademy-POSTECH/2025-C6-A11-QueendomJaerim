//
//  FrameViewModelVisibleBoundsTests.swift
//  QueenCamTests
//
//  Created by seungchan on 11/27/26.
//

import Combine
import CoreGraphics
import Foundation
import Testing
import WiFiAware

@testable import QueenCam

@MainActor
@Suite("FrameViewModel 보이는 범위 Tests")
struct FrameViewModelVisibleBoundsTests {
  // 1:1 프리뷰는 4:3 가이드 영역의 세로 0.125~0.875만 보인다(390pt / 520pt).
  private let squareBounds = CGRect(x: 0, y: 0.125, width: 1, height: 0.75)

  @Test("아래가 잘린 프레임을 만지면 크기는 그대로 두고 프리뷰 안으로 올라온다")
  func fitsCutFrameInside() {
    let viewModel = makeViewModel(bounds: squareBounds)
    viewModel.frames = [Frame(rect: CGRect(x: 0.2, y: 0.6, width: 0.4, height: 0.4))]
    let id = viewModel.frames[0].id

    let fitted = viewModel.fitInsideVisibleBounds(id: id)

    #expect(fitted == CGRect(x: 0.2, y: 0.475, width: 0.4, height: 0.4))
    #expect(viewModel.frames[0].rect == fitted)
  }

  @Test("프리뷰보다 큰 프레임은 세로만 프리뷰 높이에 맞추고 가로는 그대로 둔다")
  func shrinksOnlyHeightOfTallFrame() {
    let viewModel = makeViewModel(bounds: squareBounds)
    viewModel.frames = [Frame(rect: CGRect(x: 0.2, y: 0.05, width: 0.55, height: 0.9))]
    let id = viewModel.frames[0].id

    let fitted = viewModel.fitInsideVisibleBounds(id: id)

    #expect(fitted?.width == 0.55)
    #expect(fitted?.minX == 0.2)
    #expect(fitted?.minY == squareBounds.minY)
    #expect(fitted?.height == squareBounds.height)
  }

  @Test("이미 프리뷰 안에 있는 프레임은 그대로 두고 전송하지 않는다")
  func keepsFrameInsideAsIs() {
    let network = FakeNetworkService()
    let viewModel = makeViewModel(bounds: squareBounds, network: network)
    let rect = CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.3)
    viewModel.frames = [Frame(rect: rect)]

    let fitted = viewModel.fitInsideVisibleBounds(id: viewModel.frames[0].id)

    #expect(fitted == rect)
    #expect(network.sentEvents.isEmpty)
  }

  @Test("프레임을 옮길 때 보이는 범위 위아래를 넘지 못한다")
  func moveStaysInsideVisibleBounds() {
    let viewModel = makeViewModel(bounds: squareBounds)
    let rect = CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.3)
    viewModel.frames = [Frame(rect: rect)]
    let id = viewModel.frames[0].id
    let container = CGSize(width: 390, height: 520)

    viewModel.moveFrame(id: id, start: rect, translation: CGSize(width: 0, height: 1000), container: container)
    #expect(isClose(viewModel.frames[0].rect.maxY, squareBounds.maxY))

    viewModel.moveFrame(id: id, start: rect, translation: CGSize(width: 0, height: -1000), container: container)
    #expect(isClose(viewModel.frames[0].rect.minY, squareBounds.minY))
  }

  @Test("16:9처럼 가이드 영역보다 긴 프리뷰에서는 0 미만·1 초과 위치까지 움직일 수 있다")
  func moveCanUseOutsideGuideAreaOnLongerPreview() {
    let wideBounds = PhotoAspectRatioGeometry.guideRect(fromPreview: CGRect(x: 0, y: 0, width: 1, height: 1), ratio: .ratio16x9)
    let viewModel = makeViewModel(bounds: wideBounds)
    let rect = CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.3)
    viewModel.frames = [Frame(rect: rect)]

    viewModel.moveFrame(
      id: viewModel.frames[0].id,
      start: rect,
      translation: CGSize(width: 0, height: -1000),
      container: CGSize(width: 390, height: 520)
    )

    #expect(viewModel.frames[0].rect.minY < 0)
    #expect(isClose(viewModel.frames[0].rect.minY, wideBounds.minY))
  }

  private func makeViewModel(bounds: CGRect, network: FakeNetworkService = FakeNetworkService()) -> FrameViewModel {
    let viewModel = FrameViewModel(networkService: network, notificationService: FakeNotificationService())
    viewModel.visibleBounds = bounds
    return viewModel
  }

  private func isClose(_ lhs: CGFloat, _ rhs: CGFloat, tolerance: CGFloat = 0.000_001) -> Bool {
    abs(lhs - rhs) <= tolerance
  }
}

private final class FakeNetworkService: NetworkServiceProtocol {
  var mode: NetworkType?
  var networkState: NetworkState?
  var lastStopReason: String?
  var isCounterpartVersionVerified = false

  private(set) var sentEvents: [NetworkEvent] = []

  var deviceConnectionsPublisher: AnyPublisher<[WAPairedDevice: ConnectionDetail], Never> {
    Just([:]).eraseToAnyPublisher()
  }

  var lastErrorPublisher: AnyPublisher<Error?, Never> {
    Just(nil).eraseToAnyPublisher()
  }

  var networkStatePublisher: AnyPublisher<NetworkState?, Never> {
    Just(networkState).eraseToAnyPublisher()
  }

  var networkEventPublisher: AnyPublisher<NetworkEvent?, Never> {
    Empty().eraseToAnyPublisher()
  }

  var deviceReportsPublisher: AnyPublisher<[WAPairedDevice: WAPerformanceReport], Never> {
    Just([:]).eraseToAnyPublisher()
  }

  func run(for device: WAPairedDevice) {}
  func reconnect(for device: WAPairedDevice) {}
  func stop(byUser: Bool, userReason: String?) {}
  func disconnect() {}

  func send(for event: NetworkEvent) async {
    sentEvents.append(event)
  }
}

private final class FakeNotificationService: NotificationServiceProtocol {
  var currentNotification: DomainNotification?

  var lastNotificationPublisher: AnyPublisher<DomainNotification?, Never> {
    Empty().eraseToAnyPublisher()
  }

  func registerNotification(_ notification: DomainNotification) { currentNotification = notification }
  func reset() { currentNotification = nil }
  func registerBaseNotification(_ notification: DomainNotification) { currentNotification = notification }
  func resetBaseNotification() { currentNotification = nil }
}
