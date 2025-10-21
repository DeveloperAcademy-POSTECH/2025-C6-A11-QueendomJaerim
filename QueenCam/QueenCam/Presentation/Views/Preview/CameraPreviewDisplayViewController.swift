//
//  CameraPreviewDisplayViewController.swift
//  QueenCam
//
//  Created by 임영택 on 10/21/25.
//

import MetalKit
import OSLog
import UIKit
import CoreMedia

final class CameraPreviewDisplayViewController: UIViewController {
  // MARK: MTKView
  private let mtkView = MTKView()

  // MARK: Core Image
  private var commandQueue: MTLCommandQueue!
  private var ciContext: CIContext!
  private var offscreenTexture: MTLTexture?
  private let colorSpace = CGColorSpaceCreateDeviceRGB()

  // MARK: Current Video Frame
  private var currentPixelBuffer: CVPixelBuffer?

  // MARK: Delegate
  weak var delegate: CameraPreviewDisplayViewControllerDelegate?

  private var renderingCount: Int = 0

  // MARK: Configs
  private let timestampDiffThreshold: Double = 1.0 / 3.0  // 단위: 초
  private let countForReportingStableThreshold: Int = 150  // 단위: 횟수, 대략 5초 정도

  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam",
    category: "CameraPreviewMTKViewController"
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    mtkView.delegate = self

    configure()
    setupLayout()
  }

  private func setupLayout() {
    mtkView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(mtkView)

    NSLayoutConstraint.activate([
      mtkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      mtkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      mtkView.topAnchor.constraint(equalTo: view.topAnchor),
      mtkView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func configure() {
    guard let device = MTLCreateSystemDefaultDevice() else {
      assertionFailure("Metal is not supported on this device")
      return
    }

    mtkView.device = device
    mtkView.colorPixelFormat = .bgra8Unorm
    mtkView.framebufferOnly = false

    commandQueue = device.makeCommandQueue()
    ciContext = CIContext(mtlDevice: device)
  }
}

extension CameraPreviewDisplayViewController {
  func renderFrame(sampleBuffer: CMSampleBuffer?) {
    guard let sampleBuffer else { return }
    
    if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
      self.currentPixelBuffer = pixelBuffer
    }
  }
}

extension CameraPreviewDisplayViewController: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
  }

  func draw(in view: MTKView) {
    drawBuffer(currentPixelBuffer)
  }
}

extension CameraPreviewDisplayViewController {
  // MARK: Rendering

  private func ensureOffscreenTexture(for size: CGSize) {
    guard let device = mtkView.device else { return }
    let width = max(1, Int(size.width.rounded()))
    let height = max(1, Int(size.height.rounded()))
    if let texture = offscreenTexture, texture.width == width, texture.height == height { return }

    let desc = MTLTextureDescriptor.texture2DDescriptor(
      pixelFormat: mtkView.colorPixelFormat,
      width: width,
      height: height,
      mipmapped: false
    )
    desc.usage = [.shaderWrite, .shaderRead]  // 핵심
    desc.storageMode = .private
    offscreenTexture = device.makeTexture(descriptor: desc)
  }

  private func aspectFill(_ image: CIImage, to dst: CGSize) -> CIImage {
    let size = image.extent.size
    let scale = max(dst.width / size.width, dst.height / size.height)
    let scaled = image.transformed(by: .init(scaleX: scale, y: scale))
    let translationX = (dst.width - scaled.extent.width) * 0.5
    let translationY = (dst.height - scaled.extent.height) * 0.5
    return scaled.transformed(by: .init(translationX: translationX, y: translationY))
  }

  func drawBuffer(_ pixelBuffer: CVPixelBuffer?) {
    guard let pixelBuffer else {
      logger.warning("skip drawBuffer... frame is nil...")
      renderingCount = 0
      return
    }

    guard let drawable = mtkView.currentDrawable,
      let commandBuffer = commandQueue.makeCommandBuffer()
    else { return }

    let dstSize = mtkView.drawableSize
    ensureOffscreenTexture(for: dstSize)
    guard let offscreen = offscreenTexture else { return }

    // 1) CVPixelBuffer -> CIImage (방향 보정 필요시 oriented 사용)
    var img = CIImage(cvPixelBuffer: pixelBuffer)
    img = img.oriented(.rightMirrored)

    // 2) Aspect-Fill
    img = aspectFill(img, to: dstSize)

    // 3) CI -> Offscreen(shaderWrite)
    ciContext.render(
      img,
      to: offscreen,
      commandBuffer: commandBuffer,
      bounds: CGRect(origin: .zero, size: dstSize),
      colorSpace: colorSpace
    )

    // 4) Offscreen -> Drawable Blit
    if let blit = commandBuffer.makeBlitCommandEncoder() {
      blit.copy(
        from: offscreen,
        sourceSlice: 0,
        sourceLevel: 0,
        sourceOrigin: .init(x: 0, y: 0, z: 0),
        sourceSize: .init(width: offscreen.width, height: offscreen.height, depth: 1),
        to: drawable.texture,
        destinationSlice: 0,
        destinationLevel: 0,
        destinationOrigin: .init(x: 0, y: 0, z: 0)
      )
      blit.endEncoding()
    }

    commandBuffer.present(drawable)
    commandBuffer.commit()

    renderingCount += 1
    if renderingCount >= countForReportingStableThreshold {
      delegate?.frameDidRenderStably(viewController: self)
      renderingCount = 0
    }
  }
}

protocol CameraPreviewDisplayViewControllerDelegate: AnyObject {
  func frameDidSkipped(viewController: CameraPreviewDisplayViewController, diff: Double)
  func frameDidRenderStably(viewController: CameraPreviewDisplayViewController)
}
