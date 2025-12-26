import AVFoundation
import Combine
import Foundation
import OSLog
import Photos
import UIKit

final class CameraManager: NSObject {
  let session = AVCaptureSession()
  private let captureSessionQueue = DispatchQueue(label: "com.queendom.QueenCam.sessionQueue")
  private var videoDeviceInput: AVCaptureDeviceInput?
  private var audioDeviceInput: AVCaptureDeviceInput?
  private let photoOutput = AVCapturePhotoOutput()

  // 비디오 장치 회전을 모니터링하는 객체
  private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
  private var rotationObservers = [AnyObject]()

  /// 세션 초기화 여부를 표현하는 플래그 변수
  private(set) var isSessionConfigured: Bool = false

  // 프리뷰 프레임 캡쳐
  private let previewCaptureService: PreviewCaptureService
  // 네트워크 송수신
  let networkService: NetworkServiceProtocol
  var cancellables: Set<AnyCancellable> = []

  var position: AVCaptureDevice.Position = .back
  var flashMode: AVCaptureDevice.FlashMode = .off
  var isLivePhotoOn: Bool = false

  private let logger = QueenLogger(category: "CameraManager")

  private var inTrackingCameraDelegate: [Int64: CameraDelegate] = [:]

  // 라이브 포토에 대한 컴플리션
  var onWillCaptureLivePhoto: (() -> Void)?
  var onDidFinishCapture: (() -> Void)?
  var onPhotoCapture: ((UIImage) -> Void)?
  var onTapCameraSwitch: ((AVCaptureDevice.Position) -> Void)?

  // 카메라 촬영이 준비되는 상태 추적
  var onReadinessState: ((AVCapturePhotoOutput.CaptureReadiness) -> Void)?

  // 렌즈 변경 상태를 관찰하기 위한 옵저버
  private var lensChangeObserver: NSKeyValueObservation?

  init(previewCaptureService: PreviewCaptureService, networkService: NetworkServiceProtocol) {
    self.previewCaptureService = previewCaptureService
    self.networkService = networkService

    super.init()

    bind()  // Handle receiving network events
  }

  func configureSession() async throws {
    guard !isSessionConfigured else {
      logger.warning("capture session is already configured")
      return
    }

    try await withCheckedThrowingContinuation { continuation in
      captureSessionQueue.async { [weak self] in
        guard let self else { return }
        do {
          self.session.beginConfiguration()
          self.session.sessionPreset = .photo

          try self.setupVideoInput()
          try self.setupAudioInput()
          self.setupPhotoOutput()
          self.setupPreviewCaptureOutput()

          self.session.commitConfiguration()
          self.startSession()
          isSessionConfigured = true
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }

  func stopSession() {
    captureSessionQueue.async { [weak self] in
      guard let self else { return }
      if self.session.isRunning {
        self.session.stopRunning()
      }
    }
  }

  func capturePhoto() {
    captureSessionQueue.async { [weak self] in
      guard let self else { return }

      var photoSettings = AVCapturePhotoSettings()

      if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
        photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
      }

      if let device = videoDeviceInput?.device,
        device.isFlashAvailable,
        photoOutput.supportedFlashModes.contains(flashMode)
      {
        photoSettings.flashMode = flashMode
      } else {
        photoSettings.flashMode = .off
      }

      photoSettings.isAutoRedEyeReductionEnabled = true
      photoSettings.photoQualityPrioritization = .quality
      photoSettings.maxPhotoDimensions = photoOutput.maxPhotoDimensions

      if self.isLivePhotoOn, self.photoOutput.isLivePhotoCaptureEnabled {
        photoSettings.livePhotoMovieFileURL = URL.movieFileURL
      }

      // 1
      let uniqueID = photoSettings.uniqueID

      // 2
      let delegate = CameraDelegate(
        isCameraPosition: self.position,
        willCaptureLivePhoto: { [weak self] in
          self?.onWillCaptureLivePhoto?()
        }
      ) { [weak self] photoOutput in
        guard let self else { return }

        // 5
        self.captureSessionQueue.async {
          self.inTrackingCameraDelegate.removeValue(forKey: uniqueID)
        }

        guard let photoOutput else {
          DispatchQueue.main.async {
            self.onDidFinishCapture?()
          }
          return
        }

        // 6
        DispatchQueue.main.async {
          switch photoOutput {
          case .basicPhoto(let thumbnail, let imageData):
            self.onPhotoCapture?(thumbnail)
          case .livePhoto(let thumbnail, let imageData, let videoData):
            self.onPhotoCapture?(thumbnail)
          }
          self.onDidFinishCapture?()
        }

        self.sendPhoto(photoOutput)
      }

      // 3
      self.inTrackingCameraDelegate[uniqueID] = delegate

      // 4
      self.photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
    }
  }
}

// MARK: Session 구성
extension CameraManager {
  private func setupVideoInput() throws {
    let deviceTypeList: [AVCaptureDevice.DeviceType] = [
      .builtInTripleCamera,  // 프로 시리즈
      .builtInDualWideCamera,  // 일반 모델
      .builtInWideAngleCamera  // 단일 렌즈
    ]

    // 현재 position에 해당하는 카메라 검색
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: deviceTypeList,
      mediaType: .video,
      position: position
    )

    guard let device = discoverySession.devices.first
    else {
      logger.error("Video device is unavailable")
      return
    }

    let input = try AVCaptureDeviceInput(device: device)

    if let currentInput = videoDeviceInput {
      session.removeInput(currentInput)
    }

    if session.canAddInput(input) {
      session.addInput(input)
      videoDeviceInput = input

      createRotationCoordinator(for: device)

      do {
        try device.lockForConfiguration()
        device.videoZoomFactor = 1.0 / device.displayVideoZoomFactorMultiplier

        // 렌즈 전환 제어 설정
        if device.activePrimaryConstituentDeviceSwitchingBehavior != .unsupported {
          device.setPrimaryConstituentDeviceSwitchingBehavior(
            .restricted,
            restrictedSwitchingBehaviorConditions: .videoZoomChanged
          )
          logger.info(" Lens switching restricted to zoom changes only")
        }

        device.unlockForConfiguration()

        // 렌즈 관찰
        observeLensChange(for: device)

        logger.info("Initial zoom: \(device.videoZoomFactor)x")
      } catch {
        logger.error("Failed to set initial zoom")
        throw error
      }

    } else {
      logger.error("Couldn't add video device input to the session.")
      return
    }
  }

  // 렌즈 변경을 실시간으로 추적하는 메서드
  private func observeLensChange(for device: AVCaptureDevice) {
    lensChangeObserver?.invalidate()

    lensChangeObserver = device.observe(
      \.activePrimaryConstituent,
      options: [.new]
    ) { [weak self] device, _ in
      guard let self else { return }

      let lens = device.activePrimaryConstituent?.localizedName ?? "Unknown"
      self.logger.info("Lens Switch \(lens)")
    }
  }

  private func setupAudioInput() throws {
    guard isLivePhotoOn else { return }

    guard audioDeviceInput == nil else { return }

    guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
      logger.warning("No audio device available ")
      return
    }

    let input = try AVCaptureDeviceInput(device: audioDevice)
    if session.canAddInput(input) {
      session.addInput(input)
      audioDeviceInput = input
    }
  }

  private func setupPhotoOutput() {
    guard session.canAddOutput(photoOutput) else { return }
    session.addOutput(photoOutput)

    photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
    photoOutput.maxPhotoQualityPrioritization = .quality

    if photoOutput.isResponsiveCaptureSupported {
      photoOutput.isResponsiveCaptureEnabled = true
    }

    if photoOutput.isFastCapturePrioritizationSupported {

      photoOutput.isFastCapturePrioritizationEnabled = true
    }

    if photoOutput.isAutoDeferredPhotoDeliverySupported {
      photoOutput.isAutoDeferredPhotoDeliveryEnabled = true
    }

    if let device = videoDeviceInput?.device {
      let supportedDimensions = device.activeFormat.supportedMaxPhotoDimensions

      // 지원 해상도 리스트
      let dimensionsLog =
        supportedDimensions
        .map { "\($0.width)x\($0.height)" }
        .joined(separator: ", ")
      logger.info("Supported Dimensions: [\(dimensionsLog)]")

      // 지원 하는 해상도에서 가장 큰 것으로 설정
      if let maxDimension = supportedDimensions.max(by: { $0.width * $0.height < $1.width * $1.height }) {
        photoOutput.maxPhotoDimensions = maxDimension
      }
    }

    photoOutput.publisher(for: \.captureReadiness)
      .sink { [weak self] readiness in
        self?.logger.info("Capture readiness: \(readiness)")

        DispatchQueue.main.async { [weak self] in
          self?.onReadinessState?(readiness)
        }
      }
      .store(in: &cancellables)
  }

  private func setupPreviewCaptureOutput() {
    let previewCaptureOutput = previewCaptureService.output
    guard session.canAddOutput(previewCaptureOutput) else { return }
    session.addOutput(previewCaptureOutput)
    logger.debug("AVCaptureVideoDataOutput for AVCaptureSession added to session")
  }

  private func startSession() {
    guard !session.isRunning else { return }
    session.startRunning()
  }
}

// MARK: - 배율
extension CameraManager {
  func setZoomScale(factor: CGFloat, ramp: Bool) {
    captureSessionQueue.async { [weak self] in
      guard let self else { return }
      guard let device = videoDeviceInput?.device else {
        logger.error("Zoom failed: Device not found")
        return
      }

      do {
        try device.lockForConfiguration()

        let zoomFactor = max(
          device.minAvailableVideoZoomFactor,
          min(factor / device.displayVideoZoomFactorMultiplier, device.maxAvailableVideoZoomFactor)
        )

        if ramp {
          device.ramp(toVideoZoomFactor: zoomFactor, withRate: 4)
        } else {
          device.videoZoomFactor = zoomFactor
        }

        device.unlockForConfiguration()

        logger.info("Zoom scale set to \(String(format: "%.1f", factor))x")

      } catch {
        logger.error("Failed to configure zoom: \(error.localizedDescription)")
      }
    }
  }
}

extension CameraManager {
  func switchCamera() async throws {
    try await withCheckedThrowingContinuation { continuation in
      captureSessionQueue.async { [weak self] in
        guard let self else { return }
        self.session.beginConfiguration()

        if let currentInput = self.videoDeviceInput {
          self.session.removeInput(currentInput)
        }

        position = position == .back ? .front : .back

        do {
          try self.setupVideoInput()
          try self.setupAudioInput()
          setupPhotoOutput()

          session.commitConfiguration()

          photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported

          logger.info("Switch -> photoOutput.isLivePhotoCaptureSupported: \(photoOutput.isLivePhotoCaptureSupported)")
          logger.info("Switch -> photoOutput.isLivePhotoCaptureEnabled: \(photoOutput.isLivePhotoCaptureEnabled)")

          DispatchQueue.main.async {
            self.onTapCameraSwitch?(self.position)
          }

          continuation.resume()

        } catch {
          self.logger.error("Failed to switch camera: \(error.localizedDescription)")
          continuation.resume(throwing: error)
        }

      }
    }

    // 촬영 모드가 변경되었음을 상대에게 알린다
    await networkService.send(for: .previewRenderingMode(position == .back ? .rear : .front))
  }
}

extension CameraManager {
  func focusAndExpose(at point: CGPoint) {
    let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: point)

    guard let device = videoDeviceInput?.device else {
      logger.error("Focus failed: No active video device input.")
      return
    }

    do {
      try device.lockForConfiguration()

      if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
        device.focusPointOfInterest = devicePoint
        device.focusMode = .autoFocus
      }

      if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.autoExpose) {
        device.exposurePointOfInterest = devicePoint
        device.exposureMode = .autoExpose
      }

      device.isSubjectAreaChangeMonitoringEnabled = true
      device.unlockForConfiguration()
    } catch {
      logger.error("Focus/Exposure configuration failed: \(error.localizedDescription)")
    }
  }

  private var videoPreviewLayer: AVCaptureVideoPreviewLayer {
    guard let layer = session.connections.compactMap({ $0.videoPreviewLayer }).first else {
      logger.error("No connected preview layer found in session.")
      return AVCaptureVideoPreviewLayer(session: session)
    }
    return layer
  }
}

extension CameraManager {
  /// 지정된 장치에 대한 새 회전 코디네이터를 만들고 해당 상태를 관찰하여 회전 변경 사항을 모니터링합니다.
  private func createRotationCoordinator(for device: AVCaptureDevice) {
    // 이 장치에 대한 새 회전 코디네이터를 만듭니다.
    rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: videoPreviewLayer)

    guard let rotationCoordinator else { return }

    if let connection = photoOutput.connection(with: .video) {
      if connection.isVideoMirroringSupported {
        connection.isVideoMirrored = (position == .front)
      }
    }

    // 출력 연결에 초기 회전 상태를 설정합니다.
    updateCaptureRotation(rotationCoordinator.videoRotationAngleForHorizonLevelCapture)

    // 이전 관찰을 취소합니다.
    rotationObservers.removeAll()

    rotationObservers.append(
      rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: .new) { [weak self] _, change in
        guard let self, let angle = change.newValue else { return }
        // 캡처 미리보기 회전을 업데이트합니다.
        self.updateCaptureRotation(angle)
      }
    )
  }

  private func updateCaptureRotation(_ angle: CGFloat) {
    // 모든 출력 서비스에 대한 방향을 업데이트합니다.
    if let connection = photoOutput.connection(with: .video) {
      connection.videoRotationAngle = angle
    }
  }
}

extension URL {
  /// 라이브 포토의 mov 파일을 위한 고유한 임시 경로 생성
  static var movieFileURL: URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension(for: .quickTimeMovie)
  }
}
