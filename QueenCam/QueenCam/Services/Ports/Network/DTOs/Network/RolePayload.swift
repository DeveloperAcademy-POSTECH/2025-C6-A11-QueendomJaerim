//
//  RolePayload.swift
//  QueenCam
//
//  Created by 임영택 on 10/28/25.
//

import Foundation

struct RolePayload: Sendable, Codable {
  let myRole: Role
  let counterpartRole: Role

  init(myRole: Role) {
    self.myRole = myRole
    self.counterpartRole = myRole.counterpart
  }

  init(counterpartRole: Role) {
    self.counterpartRole = counterpartRole
    self.myRole = counterpartRole.counterpart
  }
}
