import Foundation

enum ThumbsUpEventType: Codable, Sendable {
  case remove
  case register(test: String)
}
