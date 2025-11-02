//
//  QueenLogger.swift
//  QueenCam
//
//  Created by 임영택 on 11/01/25.
//

import Foundation
import OSLog

/// OSLog와 파일에 동시에 로그를 남기는 커스텀 로거 클래스입니다.
///
/// 이 로거는 OSLog의 Logger를 래핑하여 Xcode 콘솔 및 Console.app에서 로그를 확인할 수 있게 하는 동시에,
/// 앱의 Documents 디렉토리에 있는 `QueenCam.log` 파일에도 로그를 기록합니다.
///
/// **주요 기능:**
/// - 다양한 로그 레벨(`info`, `debug`, `error`, `warning`) 지원
/// - 로그 파일 최대 크기 관리 (1MB 초과 시 오래된 로그부터 자동 삭제)
/// - 스레드 안전(Thread-safe) 파일 쓰기 보장
/// - subsystem은 앱의 Bundle Identifier로, category는 초기화 시 주입받아 사용
///
/// **사용 예시:**
/// ```swift
/// let logger = FileLogger(category: "ViewController")
/// logger.info("View did appear")
/// logger.error("Failed to load data")
/// ```
nonisolated public final class QueenLogger {
  /// 로그 레벨을 나타내는 enum
  public enum LogLevel: String {
    case info = "INFO"
    case debug = "DEBUG"
    case warning = "WARNING"
    case error = "ERROR"
  }

  private let subsystem: String
  private let category: String
  private let osLogger: Logger

  private let logFileURL: URL
  private var fileHandle: FileHandle?
  private let logQueue = DispatchQueue(label: "com.queencam.QueenDom.QueenLoggerQueue", qos: .background)

  private let maxFileSize: UInt64 = 1 * 1024 * 1024  // 1MB

  private lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    return formatter
  }()
  
  public static var defaultLogFileURL: URL {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      fatalError("Documents 디렉토리를 찾을 수 없습니다.")
    }
    return documentsDirectory.appendingPathComponent("QueenCam.log")
  }

  /// 지정된 카테고리로 로거를 초기화합니다.
  /// - Parameter category: 로그를 분류하기 위한 카테고리 문자열
  public init(category: String, logFileURL: URL? = nil) {
    self.subsystem = Bundle.main.bundleIdentifier ?? "com.queendom.QueenCam"
    self.category = category
    self.osLogger = Logger(subsystem: subsystem, category: category)

    if let logFileURL {
      self.logFileURL = logFileURL
    } else {
      self.logFileURL = Self.defaultLogFileURL
    }

    setupFileHandle()
  }

  deinit {
    logQueue.sync {
      fileHandle?.closeFile()
    }
  }

  // MARK: - Public Logging API

  /// Info 레벨의 로그를 기록합니다.
  public func info(_ message: @autoclosure () -> String) {
    let message = message()
    osLogger.info("\(message, privacy: .public)")
    log(level: .info, message: message)
  }

  /// Debug 레벨의 로그를 기록합니다.
  public func debug(_ message: @autoclosure () -> String) {
    let message = message()
    osLogger.debug("\(message, privacy: .public)")
    log(level: .debug, message: message)
  }

  /// Warning 레벨의 로그를 기록합니다.
  public func warning(_ message: @autoclosure () -> String) {
    let message = message()
    osLogger.warning("\(message, privacy: .public)")
    log(level: .warning, message: message)
  }

  /// Error 레벨의 로그를 기록합니다.
  public func error(_ message: @autoclosure () -> String) {
    let message = message()
    osLogger.error("\(message, privacy: .public)")
    log(level: .error, message: message)
  }

  // MARK: - Private Helpers

  private func setupFileHandle() {
    let path = logFileURL.path
    if !FileManager.default.fileExists(atPath: path) {
      FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
    }

    do {
      self.fileHandle = try FileHandle(forWritingTo: logFileURL)
    } catch {
      osLogger.error("로그 파일 핸들을 여는 데 실패했습니다: \(error.localizedDescription)")
    }
  }

  private func log(level: LogLevel, message: String) {
    let timestamp = dateFormatter.string(from: Date())
    let logEntry = "[\(timestamp)] [\(level.rawValue)] [\(category)] \(message)\n"

    guard let data = logEntry.data(using: .utf8) else { return }

    logQueue.async { [weak self] in
      guard let self = self else { return }
      self.writeToFile(data)
    }
  }

  private func writeToFile(_ data: Data) {
    guard let fileHandle = self.fileHandle else { return }

    do {
      // 파일 크기 확인 및 조정
      try truncateLogIfNeeded()

      // 로그 추가
      fileHandle.seekToEndOfFile()
      fileHandle.write(data)
    } catch {
      osLogger.error("로그 파일 쓰기 또는 조정 중 오류 발생: \(error.localizedDescription)")
    }
  }

  private func truncateLogIfNeeded() throws {
    guard let fileHandle = self.fileHandle else { return }

    let fileSize = (try? FileManager.default.attributesOfItem(atPath: logFileURL.path)[.size] as? NSNumber)?.uint64Value ?? 0

    if fileSize > maxFileSize {
      // 파일 핸들을 닫고 파일 내용을 읽어옵니다.
      fileHandle.closeFile()

      let data = try Data(contentsOf: logFileURL)

      // 파일 크기의 절반만 남깁니다.
      let amountToKeep = Int(maxFileSize / 2)
      let truncatedData = data.suffix(amountToKeep)

      // 잘라낸 데이터로 파일을 덮어씁니다.
      try truncatedData.write(to: logFileURL, options: .atomic)

      // 파일 핸들을 다시 엽니다.
      self.fileHandle = try FileHandle(forWritingTo: logFileURL)
      osLogger.info("로그 파일이 최대 크기를 초과하여 앞부분을 삭제했습니다.")
    }
  }
}
