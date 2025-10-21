//
//  CameraPreviewDisplayViewController.swift
//  QueenCam
//
//  Created by 임영택 on 10/21/25.
//

import AVFoundation
import OSLog
import UIKit

// MARK: - AVSampleBufferDisplayLayer를 담는 커스텀 View

/// AVSampleBufferDisplayLayer를 기본 레이어로 사용하는 UIView
private class SampleBufferDisplayView: UIView {
  /// 이 View의 기본 CALayer 클래스를 AVSampleBufferDisplayLayer로 지정합니다.
  override class var layerClass: AnyClass {
    return AVSampleBufferDisplayLayer.self
  }

  /// convenience accessor
  var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
    return self.layer as! AVSampleBufferDisplayLayer
  }
}

// MARK: - View Controller

final class CameraPreviewDisplayViewController: UIViewController {

  private var displayView: SampleBufferDisplayView!

  /// AVSampleBufferDisplayLayer의 재생 타이밍을 제어하기 위한 타임베이스
  private var controlTimebase: CMTimebase?

  // MARK: Delegate
  weak var delegate: CameraPreviewDisplayViewControllerDelegate?  // (프로토콜 이름도 수정됨)

  private var renderingCount: Int = 0

  // MARK: Configs
  private let timestampDiffThreshold: Double = 1.0 / 3.0  // 단위: 초
  private let countForReportingStableThreshold: Int = 150  // 단위: 횟수

  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam",
    category: "CameraPreviewDisplayViewController"
  )

  // MARK: - View Lifecycle

  /// UIViewController가 View를 로드할 때 호출됩니다.
  /// 기본 View를 SampleBufferDisplayView로 교체합니다.
  override func loadView() {
    displayView = SampleBufferDisplayView()
    self.view = displayView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureDisplayLayer()
  }

  private func configureDisplayLayer() {
    let layer = displayView.sampleBufferDisplayLayer

    // 1. 비디오 화면 채우기 모드 설정 (기존 aspectFill과 동일)
    layer.videoGravity = .resizeAspectFill

    // 2. 타임베이스 생성 (재생 시간 제어)
    // AVSampleBufferDisplayLayer는 자체 시계가 없으므로,
    // 호스트 시간(Host Time)을 기준으로 하는 제어 시계를 만들어 연결합니다.
    var timebase: CMTimebase?
    let status = CMTimebaseCreateWithSourceClock(
      allocator: kCFAllocatorDefault,
      sourceClock: CMClockGetHostTimeClock(),
      timebaseOut: &timebase
    )

    if status == noErr, let timebase = timebase {
      self.controlTimebase = timebase
      layer.controlTimebase = timebase
      // 타임베이스의 시간을 1.0 (정상 속도)으로 흐르게 설정
      CMTimebaseSetRate(timebase, rate: 1.0)
    } else {
      logger.critical("Failed to create control timebase. Status: \(status)")
    }
  }
}

// MARK: - 3. Public Interface (프레임 수신)

extension CameraPreviewDisplayViewController {

  /// 디코더로부터 CVPixelBuffer가 포함된 프레임을 받아 렌더링합니다.
  func renderFrame(frame: VideoFrameDecoded?) {
    guard let timebase = self.controlTimebase else {
      return
    }
    
    let layer = displayView.sampleBufferDisplayLayer

    // 1. 프레임이 nil이면, 큐를 비우고 종료 (기존 로직 동일)
    guard let frame = frame else {
      logger.warning("skip renderFrame... frame is nil. Flushing layer.")
      renderingCount = 0
      layer.flush()  // nil이 들어오면 대기 중인 프레임을 비웁니다.
      return
    }

    // 2. 프레임 지연 체크 (기존 로직 동일)
    // 타임베이스의 현재 시간을 기준으로 지연을 계산합니다.
    let currentHostTime = timebase.time
    let frameTimestamp = frame.timestamp
    let diff = currentHostTime - frameTimestamp
    let diffSeconds = diff.seconds
    diffSeconds
    if diffSeconds >= timestampDiffThreshold {
      logger.warning("frame delayed... diff=\(diffSeconds)")
      delegate?.frameDidSkipped(viewController: self, diff: diffSeconds)
      renderingCount = 0

      if frame.quality != .veryLow {
        // 너무 늦은 프레임이면 현재 큐를 비워서 다음 프레임이 빨리 보이도록 함
        layer.flushAndRemoveImage()
        return
      }
    }

    // 3. ⭐️ 핵심: CVPixelBuffer -> CMSampleBuffer 변환
    guard
      let sampleBuffer = createSampleBuffer(
        from: frame.frame,
        timestamp: frame.timestamp
      )
    else {
      logger.error("Failed to create CMSampleBuffer from CVPixelBuffer.")
      return
    }

    // 4. 레이어에 샘플 버퍼 추가 (Enqueue)
    if layer.isReadyForMoreMediaData {
      layer.enqueue(sampleBuffer)
    } else {
      // 레이어가 처리할 수 있는 버퍼 큐가 꽉 찼음 (프레임 드롭)
      logger.warning("DisplayLayer not ready for more media. Dropping frame.")
    }

    // 5. 안정적 렌더링 리포트 (기존 로직 동일)
    renderingCount += 1
    if renderingCount >= countForReportingStableThreshold {
      delegate?.frameDidRenderStably(viewController: self)
      renderingCount = 0
    }
  }
}

// MARK: - 4. Private Helper (CVPixelBuffer -> CMSampleBuffer)

extension CameraPreviewDisplayViewController {

  /// CVPixelBuffer와 타임스탬프를 AVSampleBufferDisplayLayer가 요구하는
  /// CMSampleBuffer 객체로 래핑(변환)합니다.
  private func createSampleBuffer(from pixelBuffer: CVPixelBuffer, timestamp: CMTime) -> CMSampleBuffer? {

    // 1. CVPixelBuffer로부터 CMVideoFormatDescription(포맷 정보) 생성
    var formatDescription: CMVideoFormatDescription?
    var status = CMVideoFormatDescriptionCreateForImageBuffer(
      allocator: kCFAllocatorDefault,
      imageBuffer: pixelBuffer,
      formatDescriptionOut: &formatDescription
    )
    guard status == noErr, let formatDesc = formatDescription else {
      logger.error("Failed to create CMVideoFormatDescription: \(status)")
      return nil
    }

    // 2. Date(타임스탬프)로부터 CMSampleTimingInfo(시간 정보) 생성
    // AVSampleBufferDisplayLayer는 Presentation TimeStamp(PTS)를 사용합니다.
    // 나노초(1_000_000_000) 단위의 고정밀 타임스케일 사용
    let pts = timestamp

    var timingInfo = CMSampleTimingInfo(
      duration: .invalid,  // 1회성 이미지이므로 duration 불필요
      presentationTimeStamp: pts,  // 이 프레임을 언제 보여줄 것인가
      decodeTimeStamp: .invalid  // 디코딩 시간이므로 불필요
    )

    // 3. CMSampleBuffer 생성
    var sampleBuffer: CMSampleBuffer?
    status = CMSampleBufferCreateReadyWithImageBuffer(
      allocator: kCFAllocatorDefault,
      imageBuffer: pixelBuffer,  // 래핑할 이미지 버퍼
      formatDescription: formatDesc,  // 이미지 포맷 정보
      sampleTiming: &timingInfo,  // 시간 정보
      sampleBufferOut: &sampleBuffer
    )

    guard status == noErr, let buffer = sampleBuffer else {
      logger.error("Failed to create CMSampleBuffer: \(status)")
      return nil
    }

    return buffer
  }
}

protocol CameraPreviewDisplayViewControllerDelegate: AnyObject {
  func frameDidSkipped(viewController: CameraPreviewDisplayViewController, diff: Double)
  func frameDidRenderStably(viewController: CameraPreviewDisplayViewController)
}
