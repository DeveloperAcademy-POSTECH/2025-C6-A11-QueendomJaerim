//
//  GuidingStrokeRepositoryTests.swift
//  QueenCamTests
//
//  Created by 임영택 on 6/21/26.
//

import Combine
import Foundation
import Testing
import WiFiAware

@testable import QueenCam

private final class MockGuidingNetworkService: NetworkServiceProtocol {
  var mode: NetworkType?
  var networkState: NetworkState?
  var lastStopReason: String?

  private let networkEventSubject = PassthroughSubject<NetworkEvent?, Never>()
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
    networkEventSubject.eraseToAnyPublisher()
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

  func emit(_ event: NetworkEvent) {
    networkEventSubject.send(event)
  }
}

@Suite("GuidingStrokeRepository Tests")
struct GuidingStrokeRepositoryTests {
  @Test("변경 사항을 snapshot stream과 current snapshot에 반영한다")
  func publishesSnapshots() async throws {
    let networkService = MockGuidingNetworkService()
    let repository = GuidingStrokeRepository(networkService: networkService)
    var iterator = repository.snapshots.makeAsyncIterator()

    let initial = await iterator.next()
    #expect(initial?.strokes.isEmpty == true)

    let strokeId = repository.add(
      initialPoints: [CGPoint(x: 0.1, y: 0.2), CGPoint(x: 0.3, y: 0.4)],
      isMagicPen: false,
      author: .photographer
    )

    let updated = await iterator.next()
    #expect(updated?.strokes.map(\.id) == [strokeId])
    #expect(repository.currentSnapshot().strokes.map(\.id) == [strokeId])
  }

  @Test("촬영용 stroke는 매직펜과 점이 부족한 stroke를 제외한다")
  func captureDrawableStrokesFiltersMagicPenAndShortStroke() {
    let networkService = MockGuidingNetworkService()
    let repository = GuidingStrokeRepository(networkService: networkService)

    let normalId = repository.add(
      initialPoints: [CGPoint(x: 0.1, y: 0.2), CGPoint(x: 0.3, y: 0.4)],
      isMagicPen: false,
      author: .photographer
    )
    repository.add(
      initialPoints: [CGPoint(x: 0.2, y: 0.3), CGPoint(x: 0.4, y: 0.5)],
      isMagicPen: true,
      author: .photographer
    )
    repository.add(
      initialPoints: [CGPoint(x: 0.5, y: 0.6)],
      isMagicPen: false,
      author: .model
    )

    let drawableStrokes = repository.captureDrawableStrokes()

    #expect(drawableStrokes.map(\.id) == [normalId])
    #expect(drawableStrokes.first?.author == .photographer)
  }

  @Test("네트워크 pen 이벤트를 repository 상태에 반영한다")
  func receivesNetworkPenEvents() async throws {
    let networkService = MockGuidingNetworkService()
    let repository = GuidingStrokeRepository(networkService: networkService)
    let stroke = Stroke(
      points: [CGPoint(x: 0.2, y: 0.2), CGPoint(x: 0.8, y: 0.8)],
      isMagicPen: false,
      author: .model,
      endDrawing: true
    )

    networkService.emit(.penUpdated(.add(PenMapper.convert(stroke: stroke))))
    try await Task.sleep(nanoseconds: 50_000_000)

    #expect(repository.currentSnapshot().strokes == [stroke])
  }
}
