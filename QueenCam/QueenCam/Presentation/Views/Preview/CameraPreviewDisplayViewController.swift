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
  private let minFPS: Double = 200
  private let frameRateDropThreshold = 2
  private let frameRateSkipAmount = 4
  private let adapterClock = CMClockGetHostTimeClock()

  private var lastTime = CMClockGetTime(CMClockGetHostTimeClock())
  private var adapterCounter = 0 // 너무 많은 프레임이 들어오는 경우를 조절하는 카운터
  
  private var stableRenderingCounter = 0 // 안정적으로 렌더링된 프레임 카운터
  private var reportStableRenderingThreshold: Int = 300
  
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

    let adaptedTime = CMClockGetTime(adapterClock)
    let timeDifference = CMTimeSubtract(adaptedTime, lastTime)
    let frameRate = 1 / CMTimeGetSeconds(timeDifference)

    lastTime = adaptedTime

    if frameRate > minFPS { // 너무 빠르게 프레임이 들어오면 드랍
      adapterCounter += 1

      if adapterCounter > frameRateDropThreshold && ((adapterCounter - frameRateDropThreshold) % frameRateSkipAmount) != 0 {
        // 빠르게 들어온 카운트가 임계값을 넘었을 때, frameRateSkipAmount마다 렌더링함
        return
      }
    } else {
      adapterCounter = 0
    }

    if renderer.isReadyForMoreMediaData, let sampleBuffer {
      renderer.enqueue(sampleBuffer)
      stableRenderingCounter += 1
    } else if let error = renderer.error {
      logger.error("video layer error \(error)")
      onFrameRenderUnstably?()
      stableRenderingCounter = 0
    } else {
      logger.warning("video layer has no error but not enqueued a sample buffer")
      onFrameRenderUnstably?()
      stableRenderingCounter = 0
    }

    if stableRenderingCounter >= reportStableRenderingThreshold {
      onFrameRenderStably?()
    }
  }
}

protocol CameraPreviewDisplayViewControllerDelegate: AnyObject {
  func frameDidSkipped(viewController: CameraPreviewDisplayViewController)
  func frameDidRenderStably(viewController: CameraPreviewDisplayViewController)
}
