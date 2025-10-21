//
//  HEVCEncoder.swift
//  QueenCam
//
//  Created by 임영택 on 10/21/25.
//

import CoreMedia
import Foundation
import VideoToolbox

// 인코딩된 NAL Unit을 전달하기 위한 콜백
typealias HEVCEncoderCallback = ([Data]) -> Void

class HEVCEncoder {

  private var compressionSession: VTCompressionSession?
  private var width: Int
  private var height: Int
  var callback: HEVCEncoderCallback?

  // NAL Unit을 추출하여 콜백으로 전달하는 VTCompressionOutputCallback
  private let outputCallback: VTCompressionOutputCallback = {
    (
      outputCallbackRefCon: UnsafeMutableRawPointer?,
      sourceFrameRefCon: UnsafeMutableRawPointer?,
      status: OSStatus,
      infoFlags: VTEncodeInfoFlags,
      sampleBuffer: CMSampleBuffer?
    ) in
    guard status == noErr,
      let sampleBuffer = sampleBuffer,
      let callbackRefCon = outputCallbackRefCon
    else {
      print("HEVCEncoder: Callback error or nil buffer. Status: \(status)")
      return
    }
    
    sampleBuffer.dataBuffer

    // UnsafeMutableRawPointer를 HEVCEncoder 인스턴스로 다시 캐스팅
    let encoder: HEVCEncoder = Unmanaged.fromOpaque(callbackRefCon).takeUnretainedValue()

    // 추출된 NAL Unit들을 담을 배열
    var nalUnits: [Data] = []

    let isSync = (sampleBuffer.attachments.propagated[kCMSampleAttachmentKey_NotSync as String, default: false] as? Bool) ?? false
    let isKeyFrame = !isSync

    if isKeyFrame {
      // 2. FormatDescription에서 VPS, SPS, PPS 추출
      guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }

      var paramSetCount: Int = 0
      CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(
        formatDesc,
        parameterSetIndex: 0,  // 0: VPS, 1: SPS, 2: PPS
        parameterSetPointerOut: nil,
        parameterSetSizeOut: nil,
        parameterSetCountOut: &paramSetCount,
        nalUnitHeaderLengthOut: nil
      )

      // 모든 파라미터 셋(VPS, SPS, PPS)을 순회
      for i in 0..<paramSetCount {
        var paramSetPointer: UnsafePointer<UInt8>?
        var paramSetSize: Int = 0

        let paramStatus = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(
          formatDesc,
          parameterSetIndex: i,
          parameterSetPointerOut: &paramSetPointer,
          parameterSetSizeOut: &paramSetSize,
          parameterSetCountOut: nil,
          nalUnitHeaderLengthOut: nil
        )

        if paramStatus == noErr, let paramSetPointer = paramSetPointer {
          // NAL Unit Data 생성
          let paramSetData = Data(bytes: paramSetPointer, count: paramSetSize)
          nalUnits.append(paramSetData)
        }
      }
    }

    // 3. CMBlockBuffer에서 실제 프레임(Slice) NAL Unit 추출
    // VideoToolbox는 NAL Unit 앞에 4바이트 길이(Big Endian)를 붙이는
    // 'AVCC' 포맷으로 데이터를 줍니다. (Annex B의 00 00 01 스타트 코드가 아님)

    guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

    var dataPointer: UnsafeMutablePointer<Int8>?
    var totalLength: Int = 0

    let blockBufferStatus = CMBlockBufferGetDataPointer(
      dataBuffer,
      atOffset: 0,
      lengthAtOffsetOut: nil,
      totalLengthOut: &totalLength,
      dataPointerOut: &dataPointer
    )

    if blockBufferStatus == noErr, let dataPointer = dataPointer {
      var offset: Int = 0
      // 버퍼 끝까지 4바이트 길이 + NAL Unit 데이터를 읽어들임
      while offset < totalLength {
        // 4바이트 NAL Unit 길이 (Big Endian)
        var nalUnitLength: UInt32 = 0
        memcpy(&nalUnitLength, dataPointer + offset, 4)
        nalUnitLength = CFSwapInt32BigToHost(nalUnitLength)

        offset += 4  // 길이 헤더(4바이트)만큼 오프셋 이동

        if offset + Int(nalUnitLength) > totalLength {
          // 데이터가 버퍼 길이를 초과하는 경우 (오류)
          break
        }

        // NAL Unit 데이터 생성
        let nalData = Data(bytes: dataPointer + offset, count: Int(nalUnitLength))
        nalUnits.append(nalData)

        offset += Int(nalUnitLength)  // NAL Unit 데이터만큼 오프셋 이동
      }
    }

    // 4. 추출된 모든 NAL Unit 데이터를 콜백으로 전달
    if let callback = encoder.callback, !nalUnits.isEmpty {
      callback(nalUnits)
    }
  }

  init?(width: Int, height: Int) {
    self.width = width
    self.height = height

    // 1. VTCompressionSession 생성
    let status = VTCompressionSessionCreate(
      allocator: kCFAllocatorDefault,
      width: Int32(width),
      height: Int32(height),
      codecType: kCMVideoCodecType_HEVC,
      encoderSpecification: nil,
      imageBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
      ] as CFDictionary,
      compressedDataAllocator: kCFAllocatorDefault,
      outputCallback: outputCallback,
      refcon: Unmanaged.passUnretained(self).toOpaque(),  // 'self'를 콜백으로 전달
      compressionSessionOut: &compressionSession
    )

    guard status == noErr, let session = compressionSession else {
      print("HEVCEncoder: Failed to create compression session. Status: \(status)")
      return nil
    }

    // 2. 세션 속성 설정
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_HEVC_Main_AutoLevel)
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: (width * height * 10) as CFNumber)  // 비트레이트 (예시)
    VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: 30 as CFNumber)  // 1초마다 키프레임

    // 3. 인코딩 준비
    let prepareStatus = VTCompressionSessionPrepareToEncodeFrames(session)
    guard prepareStatus == noErr else {
      print("HEVCEncoder: Failed to prepare session. Status: \(prepareStatus)")
      return nil
    }
  }

  // 4. 인코딩 실행
  func encode(sampleBuffer: CMSampleBuffer) {
    guard let session = compressionSession,
      let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    else {
      return
    }

    let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    let duration = CMSampleBufferGetDuration(sampleBuffer)

    VTCompressionSessionEncodeFrame(
      session,
      imageBuffer: imageBuffer,
      presentationTimeStamp: pts,
      duration: duration,
      frameProperties: nil,
      sourceFrameRefcon: nil,
      infoFlagsOut: nil
    )
  }

  // 5. 세션 종료
  deinit {
    if let session = compressionSession {
      VTCompressionSessionInvalidate(session)
      self.compressionSession = nil
    }
  }
}
