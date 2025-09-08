//
//  Configuration.swift
//  CodeTrack
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import Foundation
import SwiftUI

struct AppConfiguration: Codable {
  var daysCount: DaysCount = .thirty
  var filePath: String = ""
  var fileBookmark: Data?
  var isFirstLaunch: Bool = true
  var thresholds: [Threshold] = Threshold.defaultThresholds
  var startWithSystem: Bool = false

  enum DaysCount: Int, CaseIterable, Codable {
    case thirty = 30
    case sixty = 60
    case ninety = 90

    var displayName: String {
      switch self {
      case .thirty: return "30 Days"
      case .sixty: return "60 Days"
      case .ninety: return "90 Days"
      }
    }
  }

  enum CodingKeys: String, CodingKey {
    case daysCount
    case filePath
    case fileBookmark
    case isFirstLaunch
    case thresholds
    case startWithSystem
  }
}

struct Threshold: Identifiable, Codable {
  let id = UUID()
  var seconds: Int
  var color: CodableColor
  var isEditable: Bool

  var displayName: String {
    if seconds == 0 {
      return "No Activity"
    } else {
      let hours = Double(seconds) / 3600.0
      return String(format: "%.1fh", hours)
    }
  }

  static let defaultThresholds: [Threshold] = [
    Threshold(seconds: 0, color: CodableColor(.gray.opacity(0.3)), isEditable: false),
    Threshold(seconds: 3600, color: CodableColor(.green.opacity(0.3)), isEditable: true),
    Threshold(seconds: 7200, color: CodableColor(.green.opacity(0.5)), isEditable: true),
    Threshold(seconds: 14400, color: CodableColor(.green.opacity(0.7)), isEditable: true),
    Threshold(seconds: 21600, color: CodableColor(.green), isEditable: true),
    Threshold(seconds: 28800, color: CodableColor(.green.opacity(1.0)), isEditable: true),
  ]

  private enum CodingKeys: String, CodingKey {
    case seconds, color, isEditable
  }
}

struct CodableColor: Codable {
  var red: Double
  var green: Double
  var blue: Double
  var alpha: Double

  init(_ color: Color) {
    let nsColor = NSColor(color)
    let convertedColor = nsColor.usingColorSpace(.deviceRGB) ?? nsColor
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    convertedColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    self.red = Double(r)
    self.green = Double(g)
    self.blue = Double(b)
    self.alpha = Double(a)
  }

  var color: Color {
    Color(red: red, green: green, blue: blue, opacity: alpha)
  }
}

class ConfigurationManager: ObservableObject {
  @Published var configuration = AppConfiguration()

  private let userDefaults = UserDefaults.standard
  private let configurationKey = "CodeTrackConfiguration"
  private let appGroupIdentifier = "group.com.kerdofficial.CodeTrack"

  init() {
    loadConfiguration()
  }

  func saveConfiguration() {
    do {
      let data = try JSONEncoder().encode(configuration)

      userDefaults.set(data, forKey: configurationKey)

      if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
        sharedDefaults.set(data, forKey: configurationKey)
        sharedDefaults.synchronize()
        print("✅ Configuration saved to both standard and shared UserDefaults")
      } else {
        print("⚠️ Configuration saved to standard UserDefaults only (shared UserDefaults failed)")
      }
    } catch {
      print("❌ Error saving configuration: \(error)")
    }
  }

  private func loadConfiguration() {
    guard let data = userDefaults.data(forKey: configurationKey) else {
      print("ℹ️ No saved configuration, using defaults")
      saveConfiguration()
      return
    }

    do {
      configuration = try JSONDecoder().decode(AppConfiguration.self, from: data)
      print("✅ Configuration loaded")
      print("🔍 Debug - filePath: '\(configuration.filePath)'")
      print("🔍 Debug - isFirstLaunch: \(configuration.isFirstLaunch)")
      print("🔍 Debug - hasBookmark: \(configuration.fileBookmark != nil)")
      if let bookmark = configuration.fileBookmark {
        print("🔍 Debug - bookmark size: \(bookmark.count) bytes")
      }

      if !configuration.filePath.isEmpty && configuration.fileBookmark != nil {
        configuration.isFirstLaunch = false
      }

      syncToSharedUserDefaults()
    } catch {
      print("❌ Error loading configuration: \(error)")

      if let oldConfig = try? loadLegacyConfiguration(from: data) {
        print("🔄 Migrating from legacy configuration")
        configuration = oldConfig
        saveConfiguration()
      } else {
        print("ℹ️ Using default configuration")
      }
    }
  }

  private func loadLegacyConfiguration(from data: Data) throws -> AppConfiguration {
    let decoder = JSONDecoder()

    struct LegacyAppConfiguration: Codable {
      var daysCount: AppConfiguration.DaysCount = .thirty
      var filePath: String = ""
      var fileBookmark: Data?
      var thresholds: [Threshold] = Threshold.defaultThresholds
      var startWithSystem: Bool = false
    }

    let legacy = try decoder.decode(LegacyAppConfiguration.self, from: data)

    return AppConfiguration(
      daysCount: legacy.daysCount,
      filePath: legacy.filePath,
      fileBookmark: legacy.fileBookmark,
      isFirstLaunch: legacy.filePath.isEmpty,
      thresholds: legacy.thresholds,
      startWithSystem: legacy.startWithSystem
    )
  }

  private func syncToSharedUserDefaults() {
    do {
      let data = try JSONEncoder().encode(configuration)

      if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
        sharedDefaults.set(data, forKey: configurationKey)
        sharedDefaults.synchronize()
        print("✅ Configuration synced to shared UserDefaults")
      }
    } catch {
      print("❌ Error syncing configuration to shared UserDefaults: \(error)")
    }
  }

  func saveFileBookmark(for url: URL) {
    print("🔄 Creating bookmark for: \(url.path)")

    do {
      let bookmarkData = try url.bookmarkData(
        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )

      print("✅ Bookmark created successfully, size: \(bookmarkData.count) bytes")

      self.configuration.fileBookmark = bookmarkData
      self.configuration.filePath = url.path
      self.configuration.isFirstLaunch = false

      print("🔄 Saving configuration with bookmark...")
      self.saveConfiguration()
      print("✅ File bookmark and configuration saved for: \(url.path)")

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if let testData = self.userDefaults.data(forKey: self.configurationKey) {
          do {
            let testConfig = try JSONDecoder().decode(AppConfiguration.self, from: testData)
            if let testBookmark = testConfig.fileBookmark {
              print(
                "🔍 Persistence test - bookmark found in UserDefaults, size: \(testBookmark.count) bytes"
              )
              print("🔍 Persistence test - filePath: '\(testConfig.filePath)'")
              print("🔍 Persistence test - isFirstLaunch: \(testConfig.isFirstLaunch)")
            } else {
              print("⚠️ Persistence test FAILED - no bookmark in saved data")
            }
          } catch {
            print("⚠️ Persistence test FAILED - error decoding: \(error)")
          }
        } else {
          print("⚠️ Persistence test FAILED - no data in UserDefaults")
        }
      }
    } catch {
      print("❌ Error creating bookmark: \(error)")
      print("🔍 Bookmark creation error details: \(error.localizedDescription)")
    }
  }

  func accessSecureFile<T>(operation: (URL) throws -> T) -> T? {
    guard let bookmarkData = configuration.fileBookmark else {
      print("❌ No file bookmark available")
      return nil
    }

    print("🔍 Attempting to access file using bookmark (size: \(bookmarkData.count) bytes)")

    do {
      var isStale = false
      let url = try URL(
        resolvingBookmarkData: bookmarkData,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      print("✅ Bookmark resolved to URL: \(url.path)")

      if isStale {
        print("⚠️ Bookmark is stale, attempting to refresh...")
      }

      guard url.startAccessingSecurityScopedResource() else {
        print("❌ Failed to access security-scoped resource for: \(url.path)")
        return nil
      }

      print("✅ Security-scoped resource access granted")

      defer {
        url.stopAccessingSecurityScopedResource()
        print("🔄 Released security-scoped resource access")
      }

      return try operation(url)
    } catch {
      print("❌ Error accessing secure file: \(error)")
      return nil
    }
  }
}
