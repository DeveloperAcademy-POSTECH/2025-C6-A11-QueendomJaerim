//
//  PreviewModel.swift
//  QueenCam
//
//  Created by 임영택 on 10/14/25.
//

import Combine
import Foundation
import OSLog
import Transcoding
import UIKit
import WiFiAware
import AVFoundation

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
        videoDecoderAnnexBAdaptor.decode(lastReceivedFrame.data)
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

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "NetworkManager")

  init(previewCaptureService: PreviewCaptureService, networkService: NetworkServiceProtocol) {
    self.previewCaptureService = previewCaptureService
    self.networkService = networkService

    bind()

    videoDecoderTask = Task { [weak self] in
      guard let self else { return }
      
      for await decodedSampleBuffer in self.videoDecoder.decodedSampleBuffers {
        // 1. 새 타임스탬프로 '현재 호스트 시간'을 사용합니다.
        let newPTS = CMClockGetTime(CMClockGetHostTimeClock())
        var timingInfo = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: newPTS, // <-- 'nan' 대신 현재 시간으로 강제 설정
            decodeTimeStamp: .invalid
        )

        // 2. 원본 버퍼에서 이미지와 포맷 디스크립션 추출
        guard let imageBuffer = CMSampleBufferGetImageBuffer(decodedSampleBuffer),
              let formatDesc = CMSampleBufferGetFormatDescription(decodedSampleBuffer)
        else {
            logger.error("Failed to get imageBuffer or formatDesc from original buffer")
            return
        }

        // 3. 새 타이밍 정보로 CMSampleBuffer를 새로 생성
        var retimedSampleBuffer: CMSampleBuffer?
        let status = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: imageBuffer,       // 원본 이미지
            formatDescription: formatDesc,  // 원본 포맷
            sampleTiming: &timingInfo,      // <-- 새로 만든 시간 정보
            sampleBufferOut: &retimedSampleBuffer
        )

        guard status == noErr, let validBuffer = retimedSampleBuffer else {
            logger.error("Failed to create retimed sample buffer")
            return
        }
        
        self.lastReceivedCMSampleBuffer = validBuffer
      }
    }
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
      self?.logger.warning("sent stable event")
    }
  }
}
