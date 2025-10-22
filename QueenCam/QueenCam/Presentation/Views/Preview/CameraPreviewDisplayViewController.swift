//
//  CameraPreviewDisplayViewController.swift
//  QueenCam
//
//  Created by 임영택 on 10/21/25.
//

import AVFoundation
import OSLog
import UIKit

final class CameraPreviewDisplayViewController: UIViewController {
  let displayView: SampleBufferDisplayView = .init()

  weak var delegate: CameraPreviewDisplayViewControllerDelegate?

  // MARK: - Config
  let rotateDegrees: CGFloat = 90.0  // 비디오가 가로로 전송되어 플레이어 뷰를 회전시키기 위한 값

  override func viewDidLoad() {
    displayView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(displayView)
    NSLayoutConstraint.activate([
      displayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      displayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      displayView.topAnchor.constraint(equalTo: view.topAnchor),
      displayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    view.transform = CGAffineTransformMakeRotation(rotateDegrees * .pi / 180)

    displayView.onFrameRenderUnstably = { [weak self] in
      guard let self else { return }
      self.delegate?.frameDidSkipped(viewController: self)
    }

    displayView.onFrameRenderStably = { [weak self] in
      guard let self else { return }
      self.delegate?.frameDidRenderStably(viewController: self)
    }
  }

  func renderFrame(sampleBuffer: CMSampleBuffer?) {
    displayView.renderFrame(sampleBuffer)
  }
}

final class SampleBufferDisplayView: UIView {
  private let minFPS: Double = 30
  private let frameRateDropThreshold = 2
  private let frameRateSkipAmount = 4
  private let adapterClock = CMClockGetHostTimeClock()

  private var lastTime = CMClockGetTime(CMClockGetHostTimeClock())
  private var adapterCounter = 0  // 너무 많은 프레임이 들어오는 경우를 조절하는 카운터

  private var stableRenderingCounter = 0  // 안정적으로 렌더링된 프레임 카운터
  private var reportStableRenderingThreshold: Int = 300

  // MARK: 프레임 갭 감지
  private var lastPTS: CMTime?  // 마지막 프레임의 PTS 저장
  private let ptsGapThresholdSeconds: TimeInterval = 0.15  // 유실로 판단할 갭 기준 (초)

  // MARK: 네트워크 지연 감지
  private var firstPTS: CMTime?  // 동기화 기준점 (미디어 시간)
  private var firstHostTime: CMTime?  // 동기화 기준점 (현재 시간)
  private let maxAllowedDelaySeconds: TimeInterval = 0.30  // 혼잡으로 판단할 지연시간 기준 (초)

  // MARK: - Handlers
  var onFrameRenderUnstably: (() -> Void)?
  var onFrameRenderStably: (() -> Void)?

  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam",
    category: "SampleBufferDisplayView"
  )

  var videoLayer: AVSampleBufferDisplayLayer?

  override func layoutSubviews() {
    super.layoutSubviews()
    videoLayer?.removeFromSuperlayer()
    let videoLayer = AVSampleBufferDisplayLayer()
    videoLayer.backgroundColor = UIColor.black.cgColor
    videoLayer.frame = bounds
    videoLayer.videoGravity = .resizeAspect
    layer.insertSublayer(videoLayer, at: 0)
    self.videoLayer = videoLayer
  }
}

extension SampleBufferDisplayView {
  func renderFrame(_ sampleBuffer: CMSampleBuffer?) {
    guard let renderer = videoLayer?.sampleBufferRenderer else {
      logger.warning("AVSampleBufferDisplayLayer is nil. Skip rendering a frame.")
      return
    }

    // MARK: - 너무 빠르게 프레임이 들어오면 드랍

    let adaptedTime = CMClockGetTime(adapterClock)
    let timeDifference = CMTimeSubtract(adaptedTime, lastTime)
    let frameRate = 1 / CMTimeGetSeconds(timeDifference)

    lastTime = adaptedTime

    if frameRate > minFPS {
      adapterCounter += 1

      if adapterCounter > frameRateDropThreshold && ((adapterCounter - frameRateDropThreshold) % frameRateSkipAmount) != 0 {
        // 빠르게 들어온 카운트가 임계값을 넘었을 때, frameRateSkipAmount마다 렌더링함
        return
      }
    } else {
      adapterCounter = 0
    }

    // MARK: - 갭 감지

    guard let sampleBuffer else { return }

    let currentPTS = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    var isStable = true

    if let lastPTS = self.lastPTS {
      let ptsDifference = CMTimeSubtract(currentPTS, lastPTS)
      let ptsDifferenceSeconds = CMTimeGetSeconds(ptsDifference)

      if ptsDifferenceSeconds > ptsGapThresholdSeconds {
        logger.warning("Large PTS gap detected: \(ptsDifferenceSeconds)s. Frame loss.")
        isStable = false
        resetLatencyCheck()  // 기준점 리셋
      } else if ptsDifferenceSeconds < 0 {
        logger.warning("Out-of-order frame (PTS).")
        isStable = false
        resetLatencyCheck()  // 기준점 리셋
      }
    }

    // 다음 비교를 위해 현재 PTS를 저장
    self.lastPTS = currentPTS

    // MARK: - 지연 감지
    if firstPTS == nil || firstHostTime == nil {
      // (재)시작 후 첫 프레임. 두 시계를 동기화.
      logger.info("Synchronizing clocks (PTS vs Host Time).")
      firstPTS = currentPTS
      firstHostTime = adaptedTime
    }

    // 기준점이 있어야 지연 계산 가능
    if let firstPTS = self.firstPTS, let firstHostTime = self.firstHostTime {
      // 미디어 시간 경과
      let mediaDuration = CMTimeSubtract(currentPTS, firstPTS)
      // 예상되는 '현재 시간'
      let expectedHostTime = CMTimeAdd(firstHostTime, mediaDuration)
      // 실제 '현재 시간'과 비교
      let delay = CMTimeSubtract(adaptedTime, expectedHostTime)
      let delaySeconds = CMTimeGetSeconds(delay)

      if delaySeconds > maxAllowedDelaySeconds {
        logger.warning("Frame arrived late: \(delaySeconds)s. Network congestion.")
        isStable = false
      }
    }
    
    // 불안정 상태 보고 (이 프레임을 버리진 않고 일단 렌더링 시도)
    if !isStable {
      onFrameRenderUnstably?()
      stableRenderingCounter = 0
    }

    // MARK: - Enqueue new sample buffer to renderer

    if renderer.isReadyForMoreMediaData {
      renderer.enqueue(sampleBuffer)

      // PTS가 안정적이었고, 렌더러도 잘 받음
      if isStable {
        stableRenderingCounter += 1
      }
    } else if let error = renderer.error {
      logger.error("video layer error \(error)")
      onFrameRenderUnstably?()
      resetAllChecks()
    } else {
      // 백프레셔: 렌더러가 준비 안된 경우
      logger.warning("video layer has no error but not enqueued. Backpressure.")
      onFrameRenderUnstably?()
      stableRenderingCounter = 0
      // lastPTS는 리셋하지 않음. 다음 프레임이 이 프레임과 비교되어야 함.
    }

    // 안정적으로 렌더링되는 경우 보고
    if stableRenderingCounter >= reportStableRenderingThreshold {
      onFrameRenderStably?()
      stableRenderingCounter = 0
      logger.debug("Reported currently rendering stable...")
    }
  }

  /// 지연 감지 기준점을 리셋한다. (프레임 갭이 크거나 순서가 꼬였을 때 호출)
  private func resetLatencyCheck() {
    logger.info("Resetting latency check baseline.")
    firstPTS = nil
    firstHostTime = nil
  }

  /// 모든 감지 기준점을 리셋한다. (렌더러 에러 등 심각한 문제 시 호출)
  private func resetAllChecks() {
    logger.info("Resetting ALL check baselines.")
    lastPTS = nil
    firstPTS = nil
    firstHostTime = nil
    adapterCounter = 0
    stableRenderingCounter = 0
  }
}

protocol CameraPreviewDisplayViewControllerDelegate: AnyObject {
  func frameDidSkipped(viewController: CameraPreviewDisplayViewController)
  func frameDidRenderStably(viewController: CameraPreviewDisplayViewController)
}
