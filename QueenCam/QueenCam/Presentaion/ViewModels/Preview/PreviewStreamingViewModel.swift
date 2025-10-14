//
//  PreviewStreamingViewModel.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Combine
import Foundation
import OSLog
import UIKit
import WiFiAware

@Observable
final class PreviewStreamingViewModel {
  private let previewCaptureService: PreviewCaptureService
  private let networkService: NetworkServiceProtocol

  private var cancellables: Set<AnyCancellable> = []

  // MARK: - 스트리밍 관련 프로퍼티
  private let jpegToPixelBufferDecoder = JPEGToPixelBufferDecoder()

  /// Received Preview Image
  var lastReceivedFrame: VideoFramePayload? {
    didSet {
      if let lastReceivedFrame {
        if imageSize == nil {
          imageSize = lastReceivedFrame.originalSize
        }

        do {
          let imageBuffer = try jpegToPixelBufferDecoder.decode(lastReceivedFrame.frameData)
          lastReceivedFrameDecoded = VideoFrameDecoded(
            frame: imageBuffer,
            originalSize: lastReceivedFrame.originalSize,
            scaledSize: lastReceivedFrame.scaledSize,
            quality: lastReceivedFrame.quality,
            timestamp: lastReceivedFrame.timestamp
          )
        } catch {
          logger.error("error during decoding image: \(error)")
        }
      }
    }
  }

  var lastReceivedQuality: PreviewFrameQuality? {
    if let lastReceivedFrame {
      return lastReceivedFrame.quality
    }

    return nil
  }

  var lastReceivedFrameDecoded: VideoFrameDecoded?

  let imagePrecessingQueue = DispatchQueue(label: "com.queendom.QueenCam.imageProcessingQueue")

  var imageSize: CGSize?

  var previewFrameQuality: PreviewFrameQuality = .high {
    didSet {
      let newQuality = previewFrameQuality
      logger.debug("preview frame quality changed to \(String(describing: newQuality))")
    }
  }

  // MARK: - 네트워크 관련 프로퍼티
  /// 현재 네트워크가 연결되어 전송 가능함
  var transferEnabled: Bool = false
  /// 현재 캡쳐 전송 중
  var isTransfering: Bool = false
  /// 현재 네트워크 상태
  var networkState: NetworkState?
  /// 연결 목록
  var connections: [WAPairedDevice: ConnectionDetail] = [:]

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "NetworkManager")

  init(previewCaptureService: PreviewCaptureService, networkService: NetworkServiceProtocol) {
    self.previewCaptureService = previewCaptureService
    self.networkService = networkService

    bind()
  }

  private func bind() {
    networkService.networkStatePublisher
      .compactMap { $0 }
      .sink { [weak self] state in
        self?.networkState = state
        self?.transferEnabled = state != .host(.stopped) && state != .viewer(.stopped)
        print("networkStatePublisher sink -- transferEnabled=\(self?.transferEnabled)")
      }
      .store(in: &cancellables)

    networkService.deviceConnectionsPublisher
      .compactMap { $0 }
      .sink { [weak self] connections in
        self?.connections = connections
      }
      .store(in: &cancellables)

    networkService.networkEventPublisher
      .compactMap { $0 }
      .sink { [weak self] event in
        switch event {
        case .previewFrame(let framePayload):
          self?.handleReceivedFrame(framePayload)
          self?.logger.debug("previewFrame \(framePayload.timestamp)")
        case .renderState(let state):
          self?.handleReceivedRenderStateReport(state)
        default: break
        }
      }
      .store(in: &cancellables)
  }

  // MARK: Handlers
  private func handleReceivedFrame(_ frame: VideoFramePayload) {
    self.lastReceivedFrame = frame
  }

  private func handleReceivedRenderStateReport(_ state: RenderingState) {
    if state == .stable {
      logger.debug("client report that stream is stable")
      previewFrameQuality = previewFrameQuality.getBetter()
    } else {
      logger.debug("client report that stream is unstable")
      previewFrameQuality = previewFrameQuality.getWorse()
    }
  }
}

extension PreviewStreamingViewModel {
  func startCapture() {
    isTransfering = true

    Task.detached { [weak self] in
      guard let self else { return }
      
      let framePayloadStream = await self.previewCaptureService.framePayloadStream
      await previewCaptureService.startCapturePreviewStream()
      for await payload in framePayloadStream {
        await self.networkService.send(for: .previewFrame(payload))
      }
    }
  }
}
