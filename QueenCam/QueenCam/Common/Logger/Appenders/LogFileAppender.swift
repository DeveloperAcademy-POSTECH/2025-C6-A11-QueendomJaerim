//
//  LogFileAppender.swift
//  QueenCam
//
//  Created by 임영택 on 11/3/25.
//

import Foundation
import OSLog

/// 로그 파일 I/O를 전담하는 싱글톤 클래스입니다.
/// 모든 로그 쓰기 및 파일 관리는 이 클래스의 단일 큐를 통해 순차적으로 처리되어
/// 여러 QueenLogger 인스턴스 간의 충돌(Race Condition)을 방지합니다.
nonisolated final class LogFileAppender: LogAppending {
  static let shared = LogFileAppender()

  private let logFileURL: URL
  private var fileHandle: FileHandle?

  /// 파일 IO 큐
  private let logQueue = DispatchQueue(label: "com.queencam.QueenDom.LogFileAppenderQueue", qos: .background)

  private let maxFileSize: UInt64 = 1 * 1024 * 1024  // 1MB

  /// LogFileAppender 자체의 오류를 기록하기 위한 OSLogger
  private let osLogger: Logger

  /// 로그 파일의 기본 URL
  static var defaultLogFileURL: URL {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      fatalError("Documents 디렉토리를 찾을 수 없습니다.")
    }
    return documentsDirectory.appendingPathComponent("QueenCam.log")
  }

  private lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    return formatter
  }()

  private init() {
    self.logFileURL = LogFileAppender.defaultLogFileURL
    self.osLogger = Logger(
      subsystem: Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam",
      category: "LogFileAppender"
    )

    // 파일 핸들 설정을 자신의 큐에서 동기적으로 수행
    logQueue.sync {
      self.setupFileHandle()
    }
  }

  deinit {
    logQueue.sync {
      fileHandle?.closeFile()
    }
  }

  /// QueenLogger로부터 로그 데이터를 받아 파일에 씁니다.
  func write(category: String, message: String, level: LogLevel) {
    // 큐에 추가
    logQueue.async { [weak self] in
      guard let self = self else { return }

      let timestamp = dateFormatter.string(from: Date())
      let logEntry = "[\(timestamp)] [\(level.rawValue)] [\(category)] \(message)\n"
      guard let data = logEntry.data(using: .utf8) else { return }

      self.performWrite(data)
    }
  }

  // MARK: - Private File I/O (Called on logQueue)

  /// 실제 파일 쓰기 작업을 수행합니다. (반드시 logQueue에서 호출되어야 함)
  private func performWrite(_ data: Data) {
    do {
      // 파일 크기 확인
      try truncateLogIfNeeded()

      // 파일 핸들 업데이트
      guard let fileHandle = self.fileHandle else {
        osLogger.error("파일 핸들이 truncate 직후 nil이거나 유효하지 않습니다.")
        return
      }

      // 데이터 쓰기
      _ = try fileHandle.seekToEnd()
      try fileHandle.write(contentsOf: data)

    } catch {
      osLogger.error("로그 파일 쓰기 또는 조정 중 오류 발생: \(error.localizedDescription)")
    }
  }

  /// 파일 핸들을 읽기/쓰기(업데이트) 모드로 설정합니다. (logQueue)
  private func setupFileHandle() {
    let path = logFileURL.path
    if !FileManager.default.fileExists(atPath: path) {
      FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
    }

    do {
      self.fileHandle = try FileHandle(forUpdating: logFileURL)
    } catch {
      osLogger.error("로그 파일 핸들을 여는 데 실패했습니다: \(error.localizedDescription)")
    }
  }

  /// 파일 크기를 확인하고 필요시 자릅니다. (logQueue)
  private func truncateLogIfNeeded() throws {
    guard let fileHandle = self.fileHandle else { return }

    let fileSize = try fileHandle.seekToEnd()

    if fileSize > maxFileSize {
      osLogger.info("로그 파일이 최대 크기(1MB)를 초과하여 앞부분을 삭제합니다.")

      // 파일 크기의 절반만 남긴다
      let amountToKeep = maxFileSize / 2
      let amountToRemove = fileSize - amountToKeep

      // 남길 데이터의 시작점으로 이동
      try fileHandle.seek(toOffset: amountToRemove)

      // 남길 데이터를 읽는다
      let dataToKeep = try fileHandle.readToEnd() ?? Data()

      // 1. 파일 핸들 닫기
      try fileHandle.close()

      // 2. 파일 전체 덮어쓰기
      try dataToKeep.write(to: logFileURL)

      // 3. 파일 핸들 업데이트
      self.fileHandle = try FileHandle(forUpdating: logFileURL)

      osLogger.info("로그 파일 정리를 완료했습니다.")
    }
  }
}
