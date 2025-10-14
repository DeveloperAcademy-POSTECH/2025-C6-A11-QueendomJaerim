import AVFoundation
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
  private let previewCaptureService: PreviewCaptureService
  var position: AVCaptureDevice.Position = .back
  var flashMode: AVCaptureDevice.FlashMode = .off
  var isLivePhotoOn: Bool = false

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "CameraManager")

  private var cameraDelegate: CameraDelegate?

  var onPhotoCapture: ((UIImage) -> Void)?
  var onTapCameraSwitch: ((AVCaptureDevice.Position) -> Void)?

  init(previewCaptureService: PreviewCaptureService) {
    self.previewCaptureService = previewCaptureService
  }

  func configureSession() async throws {
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

      if self.isLivePhotoOn, self.photoOutput.isLivePhotoCaptureSupported {
        photoSettings.livePhotoMovieFileURL = URL.movieFileURL
      }

      self.cameraDelegate = CameraDelegate(isCameraPosition: self.position) { image in
        guard let image else { return }

        DispatchQueue.main.async {
          self.onPhotoCapture?(image)
        }
      }

      guard let delegate = self.cameraDelegate else { return }
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
      .builtInWideAngleCamera,  // 단일 렌즈
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

      do {
        try device.lockForConfiguration()
        device.videoZoomFactor = 1.0 / device.displayVideoZoomFactorMultiplier
        device.unlockForConfiguration()
        logger.info("Initial zoom factor set to 1.0")
      } catch {
        logger.error("Failed to set initial zoom")
        throw error
      }

    } else {
      logger.error("Couldn't add video device input to the session.")
      return
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
    photoOutput.maxPhotoDimensions = .init(width: 4032, height: 3024)
    photoOutput.maxPhotoQualityPrioritization = .balanced
    photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
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
  func setZoomScale(factor: CGFloat) {
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

        device.ramp(toVideoZoomFactor: zoomFactor, withRate: 4)
        device.unlockForConfiguration()

        logger.info("Zoom scale set to \(zoomFactor)")

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

extension URL {
  /// 라이브 포토의 mov 파일을 위한 고유한 임시 경로 생성
  static var movieFileURL: URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension(for: .quickTimeMovie)
  }
}
