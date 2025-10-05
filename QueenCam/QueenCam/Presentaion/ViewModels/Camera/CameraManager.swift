import AVFoundation
import OSLog
import Photos
import UIKit

final class CameraManager: NSObject {
  let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "com.queenCam.sessionQueue")
  private var videoDeviceInput: AVCaptureDeviceInput?
  private let photoOutput = AVCapturePhotoOutput()
  var position: AVCaptureDevice.Position = .back

  private let logger = Logger(subsystem: "com.queendom.camera", category: "CameraManager")

  private var cameraDelegate: CameraDelegate?

  var onPhotoCapture: ((UIImage) -> Void)?

  func configureSession() async throws {
    try await withCheckedThrowingContinuation { continuation in
      sessionQueue.async { [weak self] in
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
    sessionQueue.async { [weak self] in
      guard let self else { return }
      if self.session.isRunning {
        self.session.stopRunning()
      }
    }
  }

  func capturePhoto() {
    sessionQueue.async { [weak self] in
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

    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
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
