import AVFoundation
import UIKit

final class CameraManager: NSObject {
  let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "com.queenCam.sessionQueue")
  private var videoDeviceInput: AVCaptureDeviceInput?
  private let photoOutput = AVCapturePhotoOutput()
  var position: AVCaptureDevice.Position = .back

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

  func stop() {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      if self.session.isRunning {
        self.session.stopRunning()
      }
    }
  }
}

extension CameraManager {
  private func setupVideoInput() throws {

    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    else {
      print("CameraManger: Video device is unavailable")
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
      print("CameraManager: Couldn't add video device input to the session.")
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
