import AVFoundation
import Foundation
import Photos
import UIKit

@Observable
@MainActor
final class CameraViewModel {
  let cameraManager: CameraManager
  let networkService: NetworkServiceProtocol
  let cameraSettingsService: CameraSettingsServiceProtocol

  var isCameraPermissionGranted = false
  var isPhotosPermissionGranted = false
  var isMicPermissionGranted = false

  var lastImage: UIImage?

  var selectedZoom: CGFloat = 1.0

  var isLivePhotoOn: Bool
  var isShowGrid: Bool
  var isFlashMode: FlashMode

  var cameraPostion: AVCaptureDevice.Position?

  var errorMessage = ""

  // MARK: Thumbnail
  private let cachingManger = PHCachingImageManager()
  var thumbnailImage: UIImage?

  private let logger = QueenLogger(category: "CameraViewModel")

  // MARK: State Toast
  private let notificationService: NotificationServiceProtocol

  init(
    previewCaptureService: PreviewCaptureService,
    networkService: NetworkServiceProtocol,
    cameraSettingsService: CameraSettingsServiceProtocol,
    notificationService: NotificationServiceProtocol
  ) {
    self.networkService = networkService
    self.cameraSettingsService = cameraSettingsService
    self.cameraManager = CameraManager(
      previewCaptureService: previewCaptureService,
      networkService: networkService
    )

    self.isLivePhotoOn = cameraSettingsService.livePhotoOn
    self.isShowGrid = cameraSettingsService.gridOn
    self.isFlashMode = cameraSettingsService.flashMode

    self.notificationService = notificationService

    cameraManager.isLivePhotoOn = isLivePhotoOn
    cameraManager.flashMode = isFlashMode.convertAVCaptureDeviceFlashMode

    cameraManager.onPhotoCapture = { [weak self] image in
      self?.lastImage = image
    }

    cameraManager.onTapCameraSwitch = { [weak self] position in
      self?.cameraPostion = position
      if position == .back {
        self?.selectedZoom = 1.0
      }
    }
  }

  func checkPermissions() async {
    let cameraGranted: Bool
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .notDetermined:
      cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
    case .authorized:
      cameraGranted = true
    default:
      cameraGranted = false
    }

    let audioGranted: Bool
    switch AVCaptureDevice.authorizationStatus(for: .audio) {
    case .notDetermined:
      audioGranted = await AVCaptureDevice.requestAccess(for: .audio)
    case .authorized:
      audioGranted = true
    default:
      audioGranted = false
    }

    let photoGranted: Bool
    switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
    case .notDetermined:
      let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
      photoGranted = (newStatus == .authorized || newStatus == .limited)
    case .authorized, .limited:
      photoGranted = true
    default:
      photoGranted = false
    }

    if cameraGranted && audioGranted {
      isCameraPermissionGranted = true
      isMicPermissionGranted = true
      isPhotosPermissionGranted = photoGranted
      try? await cameraManager.configureSession()
    }
  }

  func stopSession() {
    cameraManager.stopSession()
  }

  func capturePhoto() {
    cameraManager.capturePhoto()
  }

  func setZoom(factor: CGFloat, ramp: Bool) {
    if ramp {
      selectedZoom = factor
    }

    cameraManager.setZoomScale(factor: factor, ramp: ramp)
  }

  func switchCamera() async {
    do {
      try await cameraManager.switchCamera()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func switchFlashMode() {
    switch isFlashMode {
    case .off:
      isFlashMode = .on
      notificationService.registerNotification(DomainNotification.make(type: .flashOn))
    case .on:
      isFlashMode = .auto
      notificationService.registerNotification(DomainNotification.make(type: .flashAuto))
    case .auto:
      isFlashMode = .off
      notificationService.registerNotification(DomainNotification.make(type: .flashOff))
    }

    cameraSettingsService.flashMode = isFlashMode
    cameraManager.flashMode = isFlashMode.convertAVCaptureDeviceFlashMode
  }

  func switchLivePhoto() {
    switch isLivePhotoOn {
    case true:
      isLivePhotoOn = false
      notificationService.registerNotification(DomainNotification.make(type: .liveOff))
    case false:
      isLivePhotoOn = true
      notificationService.registerNotification(DomainNotification.make(type: .liveOn))
    }

    cameraSettingsService.livePhotoOn = isLivePhotoOn
    cameraManager.isLivePhotoOn = isLivePhotoOn
  }

  func setFocus(point: CGPoint) {
    cameraManager.focusAndExpose(at: point)
  }

  func switchGrid() {
    isShowGrid.toggle()
    cameraSettingsService.gridOn = isShowGrid
  }

  func loadThumbnail() async {
    let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

    guard status == .authorized || status == .limited else {
      logger.debug("사진 접근 권한 거부")
      return
    }

    await fetchThumbnail()
  }
  
  func showGuidingToast(isRemoteGuideHidden: Bool) {
    if isRemoteGuideHidden {
      notificationService.registerNotification(.make(type: .turnOffGuiding))
    } else {
      notificationService.registerNotification(.make(type: .turnOnGuiding))
    }
  }
}

extension CameraViewModel {
  private func fetchThumbnail() async {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.fetchLimit = 1  // 한개만 요청

    let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)

    guard let asset = result.firstObject else {
      logger.debug("가져올 사진 없음")
      return
    }

    // 이미지 생성
    await requestThumbnailImage(asset: asset)
  }

  private func requestThumbnailImage(asset: PHAsset) async {
    let targetSize = CGSize(width: 48, height: 48)
    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .exact
    options.isNetworkAccessAllowed = true

    cachingManger.requestImage(
      for: asset,
      targetSize: targetSize,
      contentMode: .aspectFill,
      options: options
    ) { result, _ in
      if let result {
        self.thumbnailImage = result
      }
    }
  }
}

extension FlashMode {
  var convertAVCaptureDeviceFlashMode: AVCaptureDevice.FlashMode {
    switch self {
    case .off:
      return .off
    case .on:
      return .on
    case .auto:
      return .auto
    }
  }
}
