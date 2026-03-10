import Foundation

struct PhotoAspectRatioPayload: Sendable, Codable {
  let ratio: PhotoAspectRatio
  let lwwRegister: LWWRegister
  
  init(ratio: PhotoAspectRatio, lwwRegister: LWWRegister) {
    self.ratio = ratio
    self.lwwRegister = lwwRegister
  }
}
