//
//  WifiAwareConfigs.swift
//  QueenCam
//
//  Created by 임영택 on 10/13/25.
//

import Network
import WiFiAware

nonisolated let appPerformanceMode: WAPerformanceMode = .realtime
nonisolated let appAccessCategory: WAAccessCategory = .interactiveVideo
nonisolated let appServiceClass: NWParameters.ServiceClass = appAccessCategory.serviceClass
nonisolated let previewServiceName = "_cam-preview._tcp"

extension WAPublishableService {
  public static var previewService: WAPublishableService {
    allServices[previewServiceName]!
  }
}

extension WASubscribableService {
  public static var previewService: WASubscribableService {
    allServices[previewServiceName]!
  }
}

extension WAAccessCategory {
  var serviceClass: NWParameters.ServiceClass {
    switch self {
    case .bestEffort: .bestEffort
    case .background: .background
    case .interactiveVideo: .interactiveVideo
    case .interactiveVoice: .interactiveVoice
    default: .bestEffort
    }
  }
}
