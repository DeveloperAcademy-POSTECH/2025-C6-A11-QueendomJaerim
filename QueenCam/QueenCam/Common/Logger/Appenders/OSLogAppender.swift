//
//  OSLogAppender.swift
//  QueenCam
//
//  Created by 임영택 on 11/3/25.
//

import Foundation
import OSLog

/// 로그 파일 I/O를 전담하는 싱글톤 클래스입니다.
/// 모든 로그 쓰기 및 파일 관리는 이 클래스의 단일 큐를 통해 순차적으로 처리되어
/// 여러 QueenLogger 인스턴스 간의 충돌(Race Condition)을 방지합니다.
nonisolated final class OSLogAppender: LogAppending {
  /// 앱 전체에서 유일하게 사용될 싱글톤 인스턴스
  static let shared = OSLogAppender()

  /// 카테고리에 대한 로거 인스턴스 맵
  private var osLoggers: [String: Logger] = [:]

  /// QueenLogger로부터 로그 데이터를 받아 파일에 씁니다.
  public func write(category: String, message: String, level: LogLevel) {
    if osLoggers[category] == nil {
      osLoggers[category] = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam", category: category)
    }

    if let logger = osLoggers[category] {
      switch level {
      case .error: logger.error("\(message, privacy: .public)")
      case .warning: logger.warning("\(message, privacy: .public)")
      case .info: logger.info("\(message, privacy: .public)")
      case .debug: logger.debug("\(message, privacy: .public)")
      }
    }
  }
}
