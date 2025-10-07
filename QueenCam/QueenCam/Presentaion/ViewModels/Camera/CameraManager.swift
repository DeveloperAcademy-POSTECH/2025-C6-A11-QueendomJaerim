import AVFoundation
import OSLog
import Photos
import UIKit

final class CameraManager: NSObject {
  let session = AVCaptureSession()
  private let captureSessionQueue = DispatchQueue(label: "com.queendom.QueenCam.sessionQueue")
  private var videoDeviceInput: AVCaptureDeviceInput?
  private let photoOutput = AVCapturePhotoOutput()
  var position: AVCaptureDevice.Position = .back

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: "CameraManager")

  private var cameraDelegate: CameraDelegate?

  var onPhotoCapture: ((UIImage) -> Void)?

  func configureSession() async throws {
    try await withCheckedThrowingContinuation { continuation in
      captureSessionQueue.async { [weak self] in
        guard let self else { return }
        do {
          self.session.beginConfiguration()
          self.session.sessionPreset = .photo

          try self.setupVideoInput()
          self.setupPhotoOutput()

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

      let photoSettings = AVCapturePhotoSettings()
      photoSettings.flashMode = .off

      self.cameraDelegate = CameraDelegate { image in
        guard let image else { return }

        self.saveToPhotoLibrary(image)

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
    } else {
      logger.error("Couldn't add video device input to the session.")
      return
    }
  }

  private func setupPhotoOutput() {
    guard session.canAddOutput(photoOutput) else { return }
    session.addOutput(photoOutput)
    photoOutput.maxPhotoDimensions = .init(width: 4032, height: 3024)
    photoOutput.maxPhotoQualityPrioritization = .balanced
  }

  private func startSession() {
    guard !session.isRunning else { return }
    session.startRunning()
  }
}

// MARK: 사진 촬영
extension CameraManager {
  private func saveToPhotoLibrary(_ image: UIImage) {
    PHPhotoLibrary.shared().performChanges {
      PHAssetChangeRequest.creationRequestForAsset(from: image)
    } completionHandler: { success, error in
      if success {
        self.logger.info("Image saved to gallery.")
      } else if let error {
        self.logger.error("Error saving image to gallery")
      }
    }
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
