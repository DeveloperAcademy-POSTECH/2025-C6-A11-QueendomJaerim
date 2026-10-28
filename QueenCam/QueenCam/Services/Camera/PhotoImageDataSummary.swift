//
//  PhotoImageDataSummary.swift
//  QueenCam
//
//  Created by seungchan on 10/24/26.
//

import Foundation
import ImageIO

/// 사진 가공 전후를 로그로 비교하기 위한 요약. 픽셀 크기·방향·형식과 HDR·심도 같은 보조 정보 포함 여부를 담는다.
nonisolated struct PhotoImageDataSummary: CustomStringConvertible {
  private static let gainMapNames: Set<String> = ["hdrGainMap", "isoGainMap"]
  private static let auxiliaryDataTypes: [(type: CFString, name: String)] = [
    (kCGImageAuxiliaryDataTypeHDRGainMap, "hdrGainMap"),
    (kCGImageAuxiliaryDataTypeISOGainMap, "isoGainMap"),
    (kCGImageAuxiliaryDataTypeDepth, "depth"),
    (kCGImageAuxiliaryDataTypeDisparity, "disparity"),
    (kCGImageAuxiliaryDataTypePortraitEffectsMatte, "portraitMatte")
  ]

  let width: Int
  let height: Int
  let orientation: UInt32?
  let type: String?
  let auxiliaryDataNames: [String]

  var description: String {
    let orientationText = orientation.map(String.init) ?? "none"
    let auxiliaryText = auxiliaryDataNames.isEmpty ? "none" : auxiliaryDataNames.joined(separator: ",")
    return "\(width)x\(height) orientation=\(orientationText) type=\(type ?? "unknown") aux=[\(auxiliaryText)]"
  }

  static func make(from imageData: Data) -> PhotoImageDataSummary? {
    guard
      let source = CGImageSourceCreateWithData(imageData as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
      let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
      let height = properties[kCGImagePropertyPixelHeight as String] as? Int
    else { return nil }

    let auxiliaryDataNames = auxiliaryDataTypes
      .filter { CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, $0.type) != nil }
      .map(\.name)

    return PhotoImageDataSummary(
      width: width,
      height: height,
      orientation: properties[kCGImagePropertyOrientation as String] as? UInt32,
      type: CGImageSourceGetType(source) as String?,
      auxiliaryDataNames: auxiliaryDataNames
    )
  }

  /// 실기기 확인용 판정. 저장 사진이 비율대로인지, 원본의 HDR 정보(gain map)가 남았는지를 ✅·❌로 나타낸다.
  /// 원본에 HDR 정보가 없으면 HDR은 "-"로 나타낸다.
  static func verdict(ratio: PhotoAspectRatio, before: PhotoImageDataSummary?, after: PhotoImageDataSummary?) -> String {
    let ratioMark = after.map { $0.matches(ratio) ? "✅" : "❌" } ?? "❌"

    let beforeGainMaps = gainMapNames.intersection(before?.auxiliaryDataNames ?? [])
    let afterGainMaps = gainMapNames.intersection(after?.auxiliaryDataNames ?? [])
    let hdrMark = beforeGainMaps.isEmpty ? "-" : (beforeGainMaps.isSubset(of: afterGainMaps) ? "✅" : "❌")

    return "\(ratio.rawValue) 촬영 → 비율 \(ratioMark) HDR \(hdrMark)"
  }

  /// 긴 변:짧은 변이 비율과 같은지 본다. 나누어떨어지지 않는 크기를 위해 짧은 변 1픽셀 오차는 허용한다.
  private func matches(_ ratio: PhotoAspectRatio) -> Bool {
    let longSide = max(width, height)
    let shortSide = min(width, height)
    return abs(longSide * ratio.shortSide - shortSide * ratio.longSide) <= ratio.longSide
  }
}
