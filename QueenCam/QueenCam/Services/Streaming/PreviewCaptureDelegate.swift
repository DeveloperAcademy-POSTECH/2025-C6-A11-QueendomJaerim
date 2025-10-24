//
//  PreviewCaptureDelegate.swift
//  QueenCam
//
//  Created by 임영택 on 10/22/25.
//

import AVFoundation

// MARK: - Delegate
nonisolated final class PreviewCaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

  let bufferStream: AsyncStream<CMSampleBuffer>
  private let bufferStreamContinuation: AsyncStream<CMSampleBuffer>.Continuation

  override init() {
    let (bufferStream, bufferStreamContinuation) = AsyncStream.makeStream(of: CMSampleBuffer.self)

    self.bufferStream = bufferStream
    self.bufferStreamContinuation = bufferStreamContinuation

    super.init()
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    bufferStreamContinuation.yield(sampleBuffer)
  }
}
