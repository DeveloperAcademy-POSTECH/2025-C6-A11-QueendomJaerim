import AVFoundation
import Combine
import Foundation
import Photos
import SwiftUI
import UIKit

@Observable
@MainActor
final class CameraViewModel {
  let cameraManager: CameraManager
  let networkService: NetworkServiceProtocol
  let cameraSettingsService: CameraSettingsServiceProtocol
  private let guidingStrokeRepository: GuidingStrokeRepositoryProtocol
  
  var isCameraPermissionGranted = false
  var isPhotosPermissionGranted = false
  var isMicPermissionGranted = false
  
  var selectedZoom: CGFloat = 1.0
  
  var isLivePhotoOn: Bool
  var isShowGrid: Bool
  var isFlashMode: FlashMode
  var photoAspectRatio: PhotoAspectRatio

  /// 비율은 작가만 바꿀 수 있어서, 보내기와 받기 모두 이 역할로 막는다.
  var currentRole: Role? {
    didSet {
      // 역할 교환으로 새 작가가 되면, 상대가 이전 작가의 늦은 값을 가질 수 있어 내 값을 다시 보낸다.
      if oldValue == .model, currentRole == .photographer {
        sendPhotoAspectRatioIfPhotographer(reason: "작가가 됨")
      }
      // 반대로 새 모델은 작가의 값을 요청한다. 새 작가의 전송이 내 역할이 바뀌기 전에 도착해 버려져도 맞출 수 있다.
      if oldValue == .photographer, currentRole == .model {
        requestPhotoAspectRatioIfModel()
      }
    }
  }

  /// 화면에 보이는 프리뷰 폭(pt). 펜 합성이 화면과 같은 두께로 그리는 데 쓴다.
  var previewWidth: CGFloat = 0
  
  var cameraPostion: AVCaptureDevice.Position?
  
  var errorMessage = ""
  
  var isCaptureButtonEnabled: Bool = true
  
  var isCapturingLivePhoto: Bool = false

  var isLivePhotoMovieFinishing: Bool = false

  var isShutterEnabled: Bool {
    isCaptureButtonEnabled && !(isLivePhotoOn && isLivePhotoMovieFinishing)
  }
  
  // MARK: Thumbnail
  var thumbnailImage: UIImage?
  private let photosLibraryObserver = PhotosLibraryObserver()
  private var displayScale: CGFloat = 1.0

  
  private let logger = QueenLogger(category: "CameraViewModel")

  private var cancellables: Set<AnyCancellable> = []

  // MARK: State Toast
  private let notificationService: NotificationServiceProtocol
  
  init(
    previewCaptureService: PreviewCaptureService,
    networkService: NetworkServiceProtocol,
    cameraSettingsService: CameraSettingsServiceProtocol,
    notificationService: NotificationServiceProtocol,
    guidingStrokeRepository: GuidingStrokeRepositoryProtocol = DependencyContainer.defaultContainer.guidingStrokeRepository,
    notificationCenter: NotificationCenter = .default
  ) {
    self.networkService = networkService
    self.cameraSettingsService = cameraSettingsService
    self.guidingStrokeRepository = guidingStrokeRepository
    self.cameraManager = CameraManager(
      previewCaptureService: previewCaptureService,
      networkService: networkService
    )
    
    self.isLivePhotoOn = cameraSettingsService.livePhotoOn
    self.isShowGrid = cameraSettingsService.gridOn
    self.isFlashMode = cameraSettingsService.flashMode
    self.photoAspectRatio = cameraSettingsService.photoAspectRatio
    
    self.notificationService = notificationService
 
    cameraManager.isLivePhotoOn = isLivePhotoOn
    cameraManager.flashMode = isFlashMode.convertAVCaptureDeviceFlashMode
    
    cameraManager.onReadinessState = { [weak self] readiness in
      self?.handleReadiness(readiness: readiness)
    }
    
    cameraManager.onPhotoCapture = { [weak self] image in
      self?.thumbnailImage = image
    }
    
    cameraManager.onTapCameraSwitch = { [weak self] position in
      self?.cameraPostion = position
      if position == .back {
        self?.selectedZoom = 1.0
      }
    }
    
    cameraManager.onWillCaptureLivePhoto = { [weak self] in
      self?.isCapturingLivePhoto = true
    }
    
    cameraManager.onDidFinishCapture = { [weak self] in
      self?.isCapturingLivePhoto = false
    }

    cameraManager.onLivePhotoMovieFinishingChange = { [weak self] isFinishing in
      self?.isLivePhotoMovieFinishing = isFinishing
    }
    
    photosLibraryObserver.onUpdate = { [weak self] image in
       self?.thumbnailImage = image
     }
     
    photosLibraryObserver.getCurrentScale = { [weak self] in
      self?.displayScale ?? 1.0
     }

    networkService.networkEventPublisher
      .receive(on: RunLoop.main)
      .compactMap { $0 }
      .sink { [weak self] event in
        switch event {
        case .photoAspectRatio(let ratio):
          self?.handleReceivedPhotoAspectRatio(ratio)
        case .requestPhotoAspectRatio:
          self?.sendPhotoAspectRatioIfPhotographer(reason: "모델 요청에 답함")
        case .myVersion:
          // NetworkService가 통과 여부를 정한 뒤에 전달하므로, 통과했다면 연결 시작·재연결의 첫 비율을 이때 보낸다.
          self?.sendPhotoAspectRatioIfPhotographer(reason: "버전 확인 통과")
        default:
          break
        }
      }
      .store(in: &cancellables)

    // 화면 갱신(onChange)까지 기다리면 그 틈에 이전 작가의 늦은 비율을 받아들여서, 역할이 바뀌는 순간 함께 바꾼다.
    notificationCenter.publisher(for: .QueenCamRoleChangedNotification)
      .compactMap { $0.userInfo?["newRole"] as? Role }
      .sink { [weak self] role in
        self?.currentRole = role
      }
      .store(in: &cancellables)
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
    traceShutterPressedEvent()
    guard cameraSettingsService.saveGuidingOverlayImageOn else {
      cameraManager.capturePhoto(aspectRatio: photoAspectRatio)
      return
    }

    cameraManager.capturePhoto(
      aspectRatio: photoAspectRatio,
      drawableStrokes: guidingStrokeRepository.captureDrawableStrokes(),
      previewWidth: previewWidth
    )
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
  
  func showLivePhotoToast() {
    notificationService.registerNotification(DomainNotification.make(type: .captureLivePhoto))
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
  
  func switchPhotoAspectRatio() {
    photoAspectRatio = photoAspectRatio.next()
    cameraSettingsService.photoAspectRatio = photoAspectRatio
    sendPhotoAspectRatioIfPhotographer(reason: "비율 변경")
  }

  private func requestPhotoAspectRatioIfModel() {
    guard currentRole == .model, networkService.isCounterpartVersionVerified else { return }

    logger.info("[AspectRatio] 모델이 되어 작가에게 비율 요청")
    Task {
      await networkService.send(for: .requestPhotoAspectRatio)
    }
  }

  private func sendPhotoAspectRatioIfPhotographer(reason: String) {
    guard currentRole == .photographer, networkService.isCounterpartVersionVerified else { return }

    let ratio = photoAspectRatio
    logger.info("[AspectRatio] \(reason): 모델에게 비율 \(ratio.rawValue) 전송")
    Task {
      await networkService.send(for: .photoAspectRatio(ratio))
    }
  }

  private func handleReceivedPhotoAspectRatio(_ ratio: PhotoAspectRatio) {
    guard currentRole == .model else {
      logger.info("[AspectRatio] 모델이 아니라서 받은 비율 \(ratio.rawValue) 무시")
      return
    }

    photoAspectRatio = ratio
    cameraSettingsService.photoAspectRatio = ratio
    logger.info("[AspectRatio] 작가 비율 \(ratio.rawValue) 받아 저장")
  }

  func setFocus(point: CGPoint) {
    cameraManager.focusAndExpose(at: point)
  }
  
  func switchGrid() {
    isShowGrid.toggle()
    cameraSettingsService.gridOn = isShowGrid
  }
  
  func loadThumbnail(scale: CGFloat) async {
    await photosLibraryObserver.loadThumbnail(scale: scale)
  }
  
  func managePhotosPickerToast(isShowPhotosPicker: Bool) {
    if isShowPhotosPicker {
      notificationService.registerNotification(.make(type: .photosPickerShowing))
    } else {
      if let currentNotification = notificationService.currentNotification,
         currentNotification.isType(of: .photosPickerShowing)
      {
        notificationService.reset()
      }
    }
  }
}

extension CameraViewModel {
  private func handleReadiness(readiness: AVCapturePhotoOutput.CaptureReadiness) {
    switch readiness {
    case .sessionNotRunning:
      isCaptureButtonEnabled = false
    case .ready:
      isCaptureButtonEnabled = true
    case .notReadyMomentarily:
      isCaptureButtonEnabled = false
    case .notReadyWaitingForCapture:
      isCaptureButtonEnabled = false
    case .notReadyWaitingForProcessing:
      isCaptureButtonEnabled = false
    @unknown default:
      isCaptureButtonEnabled = false
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
