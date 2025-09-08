//
//  LoginItemManager.swift
//  CodeTrack
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import Foundation
import ServiceManagement

class LoginItemManager {
  static let shared = LoginItemManager()

  private init() {}

  var isEnabledAsLoginItem: Bool {
    get {
      if #available(macOS 13.0, *) {
        return SMAppService.mainApp.status == .enabled
      } else {
        return UserDefaults.standard.bool(forKey: "LaunchAtLogin")
      }
    }
    set {
      if #available(macOS 13.0, *) {
        do {
          if newValue {
            try SMAppService.mainApp.register()
          } else {
            try SMAppService.mainApp.unregister()
          }
        } catch {
          print("❌ Failed to \(newValue ? "enable" : "disable") login item: \(error)")
        }
      } else {
        UserDefaults.standard.set(newValue, forKey: "LaunchAtLogin")
      }
    }
  }
}
