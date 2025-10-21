//
//  HEVCDecoder.swift
//  QueenCam
//
//  Created by 임영택 on 10/21/25.
//

import CoreMedia
import Foundation
import VideoToolbox

// 수신측에서 NAL Unit 타입을 식별하기 위한 헬퍼 (HEVC 기준)
// (NAL Unit Header의 1번째 바이트를 파싱)
private enum NALUnitType: UInt8 {
  case vps = 32  // Video Parameter Set
  case sps = 33  // Sequence Parameter Set
  case pps = 34  // Picture Parameter Set
  case vcl = 19  // Coded slice of an IDR picture (키프레임)
  // 0...31 범위는 VCL NAL Unit (P/B 프레임 등)

  init?(data: Data) {
    guard !data.isEmpty else { return nil }
    // NAL Unit Type은 첫 바이트의 1번 비트부터 6개 비트 (>> 1 & 0x3F)
    let nalUnitType = (data[0] >> 1) & 0x3F

    if nalUnitType < 32 {
      self = .vcl  // VCL (비디오 슬라이스)로 통칭
    } else {
      self.init(rawValue: nalUnitType)
    }
  }
}

class HEVCDecoder {

  private var decompressionSession: VTDecompressionSession?
  private var formatDescription: CMVideoFormatDescription?

  // 디코딩 큐 (메인 스레드 방해 금지)
  private let decodingQueue = DispatchQueue(label: "com.queencam.decoder.queue")

  // 디코딩 완료시 CVPixelBuffer를 전달하는 콜백
  public var onFrameDecoded: ((CVPixelBuffer, CMTime) -> Void)?

  // C-스타일 콜백 함수 (VTDecompressionOutputCallback)
  // 비동기로 디코딩이 완료되면 이 함수가 호출됩니다.
  private let outputCallback: VTDecompressionOutputCallback = {
    (
      decompressionOutputRefCon: UnsafeMutableRawPointer?,
      sourceFrameRefCon: UnsafeMutableRawPointer?,
      status: OSStatus,
      infoFlags: VTDecodeInfoFlags,
      imageBuffer: CVImageBuffer?,
      presentationTimeStamp: CMTime,
      duration: CMTime
    ) in
    guard status == noErr,
      let imageBuffer = imageBuffer,
      let decoderRefCon = decompressionOutputRefCon
    else {
      print("HEVCDecoder: Callback error status=\(status)")
      return
    }

    // 'self' 참조 복원
    let decoder: HEVCDecoder = Unmanaged.fromOpaque(decoderRefCon).takeUnretainedValue()

    // 디코딩된 CVPixelBuffer(CVImageBuffer)를 Swift 콜백으로 전달
    decoder.onFrameDecoded?(imageBuffer, presentationTimeStamp)
  }

  init() {}

  deinit {
    invalidate()
  }

  private func invalidate() {
    if let session = decompressionSession {
      VTDecompressionSessionWaitForAsynchronousFrames(session)
      VTDecompressionSessionInvalidate(session)
      decompressionSession = nil
    }
    formatDescription = nil
  }

  // 네트워크 등에서 NAL Unit 묶음을 받았을 때 호출할 메인 함수
  public func decode(nalUnits: [Data], pts: CMTime) {
    // 디코딩 작업은 백그라운드 큐에서 수행
    decodingQueue.async { [weak self] in
      self?._decode(nalUnits: nalUnits, pts: pts)
    }
  }

  private func _decode(nalUnits: [Data], pts: CMTime) {
    var vps: Data?
    var sps: Data?
    var pps: Data?
    var vclNals: [Data] = []

    // 1. NAL Unit들을 파라미터 셋(VPS/SPS/PPS)과 VCL(영상 프레임)로 분리
    for nalData in nalUnits {
      switch NALUnitType(data: nalData) {
      case .vps: vps = nalData
      case .sps: sps = nalData
      case .pps: pps = nalData
      case .vcl: vclNals.append(nalData)
      default: vclNals.append(nalData)  // 기타 슬라이스
      }
    }

    // 2. 파라미터 셋이 새로 들어왔다면 디코더(DecompressionSession)를 (재)생성
    if let vps = vps, let sps = sps, let pps = pps {
      // 새 파라미터로 FormatDescription 생성 시도
      if !createFormatDescription(vps: vps, sps: sps, pps: pps) {
        print("HEVCDecoder: Failed to create FormatDescription")
//        return
      }

      // FormatDescription이 변경되었으므로 세션 재생성
      if !createDecompressionSession() {
        print("HEVCDecoder: Failed to create DecompressionSession")
//        return
      }
    }

    // 3. VCL NAL Unit(영상 프레임) 디코딩
    guard decompressionSession != nil else {
      print("HEVCDecoder: Session not ready. Waiting for Parameter Sets (VPS, SPS, PPS)...")
      return
    }

    for vclNal in vclNals {
      decodeVCL(nalUnit: vclNal, pts: pts)
    }
  }

  // 1. 파라미터 셋(Data)으로 CMVideoFormatDescription 생성
  private func createFormatDescription(vps: Data, sps: Data, pps: Data) -> Bool {
    // Data를 [UInt8] 배열로 변환 (UnsafePointer로 전달하기 위함)
    let vpsBytes = [UInt8](vps)
    let spsBytes = [UInt8](sps)
    let ppsBytes = [UInt8](pps)

    // 포인터 배열 준비
    let paramSetPointers: [UnsafePointer<UInt8>] = [
      UnsafePointer(vpsBytes),
      UnsafePointer(spsBytes),
      UnsafePointer(ppsBytes),
    ]

    let paramSetSizes: [Int] = [vpsBytes.count, spsBytes.count, ppsBytes.count]

    var newFormatDesc: CMVideoFormatDescription?
    let status = CMVideoFormatDescriptionCreateFromHEVCParameterSets(
      allocator: kCFAllocatorDefault,
      parameterSetCount: 3,  // VPS, SPS, PPS
      parameterSetPointers: paramSetPointers,
      parameterSetSizes: paramSetSizes,
      nalUnitHeaderLength: 4,  // 4바이트 길이 (AVCC 포맷) - 중요
      extensions: nil,
      formatDescriptionOut: &newFormatDesc
    )

    if status == noErr, let newFormatDesc = newFormatDesc {
      // 기존 FormatDescription과 다른 경우에만 업데이트
      if self.formatDescription == nil || !CMFormatDescriptionEqual(self.formatDescription, otherFormatDescription: newFormatDesc) {
        print("HEVCDecoder: FormatDescription Aquired/Updated.")
        print(newFormatDesc)
        self.formatDescription = newFormatDesc
        return true  // 변경됨
      }
    }
    return false  // 변경 없음 (또는 실패)
  }

  // 2. CMVideoFormatDescription으로 VTDecompressionSession 생성
  private func createDecompressionSession() -> Bool {
    guard let formatDesc = self.formatDescription else { return false }

    // 기존 세션이 있다면 무효화
    if let session = decompressionSession {
      VTDecompressionSessionWaitForAsynchronousFrames(session)
      VTDecompressionSessionInvalidate(session)
      self.decompressionSession = nil
    }

    // 디코딩된 이미지(CVPixelBuffer)의 속성
    let decoderParameters =
      [
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
      ] as [CFString: Any]

    // 콜백 설정
    var outputCallbackRecord = VTDecompressionOutputCallbackRecord(
      decompressionOutputCallback: outputCallback,
      decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque()  // 'self' 전달
    )

    var session: VTDecompressionSession?
    let status = VTDecompressionSessionCreate(
      allocator: kCFAllocatorDefault,
      formatDescription: formatDesc,
      decoderSpecification: nil,
      imageBufferAttributes: decoderParameters as CFDictionary,
      outputCallback: &outputCallbackRecord,
      decompressionSessionOut: &session
    )

    guard status == noErr else {
      print("HEVCDecoder: Failed to create session. Status: \(status)")
      return false
    }

    self.decompressionSession = session
    print("HEVCDecoder: Decompression Session Created.")
    return true
  }

  // 3. 실제 VCL NAL Unit 디코딩 요청
  private func decodeVCL(nalUnit: Data, pts: CMTime) {
    guard let session = self.decompressionSession else { return }

    // 1. CMBlockBuffer 생성 (AVCC 포맷: 4바이트 Big Endian 길이 + NAL Unit 데이터)
    var blockBuffer: CMBlockBuffer?
    var nalUnitLength = CFSwapInt32HostToBig(UInt32(nalUnit.count))  // Big Endian
    let lengthBytes = Data(bytes: &nalUnitLength, count: 4)

    var status = CMBlockBufferCreateWithMemoryBlock(
      allocator: kCFAllocatorDefault,
      memoryBlock: nil,  // 널으로 하면 내부에서 할당
      blockLength: nalUnit.count + 4,
      blockAllocator: kCFAllocatorDefault,
      customBlockSource: nil,
      offsetToData: 0,
      dataLength: nalUnit.count + 4,
      flags: 0,
      blockBufferOut: &blockBuffer
    )

    guard status == noErr, let blockBuffer = blockBuffer else {
      print("HEVCDecoder: Failed to create BlockBuffer")
      return
    }

    // 2. 생성된 BlockBuffer에 데이터 채우기 (길이 + NALU)
    CMBlockBufferReplaceDataBytes(
      with: UnsafeRawPointer([UInt8](lengthBytes)),
      blockBuffer: blockBuffer,
      offsetIntoDestination: 0,
      dataLength: 4
    )

    CMBlockBufferReplaceDataBytes(
      with: UnsafeRawPointer([UInt8](nalUnit)),
      blockBuffer: blockBuffer,
      offsetIntoDestination: 4,
      dataLength: nalUnit.count
    )

    // 3. CMSampleBuffer 생성
    var sampleBuffer: CMSampleBuffer?
    var sampleSizeArray = [nalUnit.count + 4]
    var timingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: pts, decodeTimeStamp: .invalid)

    status = CMSampleBufferCreateReady(
      allocator: kCFAllocatorDefault,
      dataBuffer: blockBuffer,
      formatDescription: self.formatDescription,
      sampleCount: 1,
      sampleTimingEntryCount: 1,
      sampleTimingArray: &timingInfo,
      sampleSizeEntryCount: 1,
      sampleSizeArray: &sampleSizeArray,
      sampleBufferOut: &sampleBuffer
    )

    guard status == noErr, let sampleBuffer = sampleBuffer else {
      print("HEVCDecoder: Failed to create SampleBuffer")
      return
    }

    // 4. 비동기 디코딩 요청
    VTDecompressionSessionDecodeFrame(
      session,
      sampleBuffer: sampleBuffer,
      flags: [._EnableAsynchronousDecompression],
      frameRefcon: nil,
      infoFlagsOut: nil
    )
  }
}
