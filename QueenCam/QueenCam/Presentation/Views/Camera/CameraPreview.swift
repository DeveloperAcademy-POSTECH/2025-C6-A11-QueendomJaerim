import AVFoundation
import SwiftUI

struct CameraPreview: UIViewRepresentable {

  let session: AVCaptureSession

  func makeUIView(context: Context) -> VideoPreview {
    let view = VideoPreview()
    view.backgroundColor = .black
    view.videoPreviewLayer.session = session
    view.videoPreviewLayer.videoGravity = .resizeAspect
    return view
  }

  public func updateUIView(_ uiView: VideoPreview, context: Context) {}

  class VideoPreview: UIView {

    override class var layerClass: AnyClass {
      AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
      return layer as! AVCaptureVideoPreviewLayer
    }
  }
}
