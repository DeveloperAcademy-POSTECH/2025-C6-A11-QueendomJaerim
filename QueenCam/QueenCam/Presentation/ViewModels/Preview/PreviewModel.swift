//
//  PreviewModel.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import AVFoundation
import Combine
import Foundation
import OSLog
import Transcoding
import UIKit
import WiFiAware

@Observable
final class PreviewModel {
  private let previewCaptureService: PreviewCaptureService
  private let networkService: NetworkServiceProtocol

  private var cancellables: Set<AnyCancellable> = []

  // MARK: - 스트리밍 관련 프로퍼티
  @ObservationIgnored let videoDecoder = VideoDecoder(config: .init(realTime: true))
  @ObservationIgnored lazy var videoDecoderAnnexBAdaptor = VideoDecoderAnnexBAdaptor(videoDecoder: videoDecoder, codec: .hevc)
  @ObservationIgnored var videoDecoderTask: Task<Void, Never>?

  /// Received Preview Image
  var lastReceivedFrame: VideoFramePayload? {
    didSet {
      if let lastReceivedFrame {
        lastReceivedTime = Date()

        videoDecoderAnnexBAdaptor.decode(
          AnnexBPayload(
            annexBData: lastReceivedFrame.hevcData,
            firstFrameTimestamp: lastReceivedFrame.firstFrameTimeStamp,
            presentationTimestamp: lastReceivedFrame.presetationTimeStamp
          )
        )
      }
    }
  }

  var lastReceivedQuality: PreviewFrameQuality? {
    if let lastReceivedFrame {
      return lastReceivedFrame.quality
    }

    return nil
  }

  var lastReceivedCMSampleBuffer: CMSampleBuffer?

  var lastReceivedTime: Date? = nil

  let imagePrecessingQueue = DispatchQueue(label: "com.queendom.QueenCam.imageProcessingQueue")

  var imageSize: CGSize?

  var previewFrameQuality: PreviewFrameQuality = .high {
    didSet {
      logger.debug("preview frame quality changed to \(String(describing: self.previewFrameQuality))")
      Task {
        await self.previewCaptureService.setQuality(to: self.previewFrameQuality)
      }
    }
  }

  // MARK: - 네트워크 관련 프로퍼티
  /// 현재 네트워크가 연결되어 전송 가능함
  var transferEnabled: Bool = false {
    didSet {
      if !transferEnabled {
        stopCapture()
      }
    }
  }
  /// 현재 캡쳐 전송 중
  var isTransfering: Bool = false
  /// 현재 네트워크 상태
  var networkState: NetworkState?
  /// 연결 목록
  var connections: [WAPairedDevice: ConnectionDetail] = [:]

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "PreviewModel")

  init(previewCaptureService: PreviewCaptureService, networkService: NetworkServiceProtocol) {
    self.previewCaptureService = previewCaptureService
    self.networkService = networkService

    bind()

    videoDecoderTask = Task { [weak self] in
      guard let self else { return }

      for await decodedSampleBuffer in self.videoDecoder.decodedSampleBuffers {
        self.lastReceivedCMSampleBuffer = decodedSampleBuffer
      }
    }
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(roleChangeNotificationHandler(notification:)),
      name: .QueenCamRoleChangedNotification,
      object: nil
    )
  }

  private func bind() {
    networkService.networkStatePublisher
      .compactMap { $0 }
      .sink { [weak self] state in
        self?.networkState = state
        self?.transferEnabled = state != .host(.stopped) && state != .viewer(.stopped)
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
        case .renderState(let state):
          self?.handleReceivedRenderStateReport(state)
        default: break
        }
      }
      .store(in: &cancellables)
  }
  
  @objc private func roleChangeNotificationHandler(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let newRole = userInfo["newRole"] as? Role else { return }
    handleRoleChanged(newRole: newRole)
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

  private func handleRoleChanged(newRole: Role) {
    if newRole == .photographer {
      logger.info("started preview capture because the counterpart requested change role")
      self.startCapture()
    } else if newRole == .model {
      logger.info("stopped preview capture because the counterpart requested change role")
      self.stopCapture()
    }
  }
}

// MARK: - Photographer's Intent
extension PreviewModel {
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

  func stopCapture() {
    isTransfering = false

    Task.detached { [weak self] in
      await self?.previewCaptureService.stopCapturePreviewStream()
    }
  }
}

// MARK: Model's Intent
extension PreviewModel {
  // MARK: 화질 조정

  func frameDidSkipped() {
    Task.detached { [weak self] in
      await self?.networkService.send(for: .renderState(.unstable))
      self?.logger.warning("sent unstable event")
    }
  }

  func frameDidRenderStablely() {
    Task.detached { [weak self] in
      await self?.networkService.send(for: .renderState(.stable))
      // self?.logger.debug("sent stable event")
    }
  }
}
