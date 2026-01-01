//
//  Configuration.swift
//  CodeTrack
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import Foundation
import SwiftUI

struct DataSource: Identifiable, Codable {
  let id: UUID
  var name: String
  var filePath: String
  var fileBookmark: Data?
  var isEnabled: Bool
  
  init(id: UUID = UUID(), name: String = "", filePath: String = "", fileBookmark: Data? = nil, isEnabled: Bool = true) {
    self.id = id
    self.name = name
    self.filePath = filePath
    self.fileBookmark = fileBookmark
    self.isEnabled = isEnabled
  }
}

struct AppConfiguration: Codable {
  var daysCount: DaysCount = .thirty
  var dataSources: [DataSource] = []
  
  // Legacy properties for migration
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
    case dataSources
    case filePath
    case fileBookmark
    case isFirstLaunch
    case thresholds
    case startWithSystem
  }
  
  var hasConfiguredDataSources: Bool {
    return !dataSources.isEmpty && dataSources.contains { !$0.filePath.isEmpty && $0.fileBookmark != nil }
  }
  
  var enabledDataSources: [DataSource] {
    return dataSources.filter { $0.isEnabled && !$0.filePath.isEmpty && $0.fileBookmark != nil }
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
      print("🔍 Debug - dataSources count: \(configuration.dataSources.count)")
      print("🔍 Debug - isFirstLaunch: \(configuration.isFirstLaunch)")
      
      // Migrate legacy single file path to data sources
      if !configuration.filePath.isEmpty && configuration.fileBookmark != nil && configuration.dataSources.isEmpty {
        print("🔄 Migrating legacy file path to data sources")
        let legacySource = DataSource(
          name: "Primary Data Source",
          filePath: configuration.filePath,
          fileBookmark: configuration.fileBookmark,
          isEnabled: true
        )
        configuration.dataSources.append(legacySource)
        configuration.filePath = ""
        configuration.fileBookmark = nil
        saveConfiguration()
      }

      if configuration.hasConfiguredDataSources {
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
    
    var dataSources: [DataSource] = []
    if !legacy.filePath.isEmpty {
      dataSources.append(DataSource(
        name: "Primary Data Source",
        filePath: legacy.filePath,
        fileBookmark: legacy.fileBookmark,
        isEnabled: true
      ))
    }

    return AppConfiguration(
      daysCount: legacy.daysCount,
      dataSources: dataSources,
      filePath: "",
      fileBookmark: nil,
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

  func saveFileBookmark(for url: URL, dataSourceId: UUID? = nil) {
    print("🔄 Creating bookmark for: \(url.path)")

    do {
      let bookmarkData = try url.bookmarkData(
        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )

      print("✅ Bookmark created successfully, size: \(bookmarkData.count) bytes")

      if let sourceId = dataSourceId, let index = self.configuration.dataSources.firstIndex(where: { $0.id == sourceId }) {
        // Update existing data source
        self.configuration.dataSources[index].fileBookmark = bookmarkData
        self.configuration.dataSources[index].filePath = url.path
        print("✅ Updated data source at index \(index)")
      } else {
        // Add new data source
        let newSource = DataSource(
          name: "Data Source \(self.configuration.dataSources.count + 1)",
          filePath: url.path,
          fileBookmark: bookmarkData,
          isEnabled: true
        )
        self.configuration.dataSources.append(newSource)
        print("✅ Added new data source")
      }
      
      self.configuration.isFirstLaunch = false

      print("🔄 Saving configuration with bookmark...")
      self.saveConfiguration()
      print("✅ File bookmark and configuration saved for: \(url.path)")

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if let testData = self.userDefaults.data(forKey: self.configurationKey) {
          do {
            let testConfig = try JSONDecoder().decode(AppConfiguration.self, from: testData)
            print("🔍 Persistence test - dataSources count: \(testConfig.dataSources.count)")
            for (index, source) in testConfig.dataSources.enumerated() {
              print("🔍 Persistence test - Source \(index): \(source.name), enabled: \(source.isEnabled)")
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
  
  func removeDataSource(_ id: UUID) {
    configuration.dataSources.removeAll { $0.id == id }
    if configuration.dataSources.isEmpty {
      configuration.isFirstLaunch = true
    }
    saveConfiguration()
  }
  
  func updateDataSourceName(_ id: UUID, name: String) {
    if let index = configuration.dataSources.firstIndex(where: { $0.id == id }) {
      configuration.dataSources[index].name = name
      saveConfiguration()
    }
  }
  
  func toggleDataSource(_ id: UUID) {
    if let index = configuration.dataSources.firstIndex(where: { $0.id == id }) {
      configuration.dataSources[index].isEnabled.toggle()
      saveConfiguration()
    }
  }

  func accessSecureFile<T>(operation: (URL) throws -> T) -> T? {
    // Legacy support - if dataSources is empty but we have old bookmark
    if configuration.dataSources.isEmpty, let bookmarkData = configuration.fileBookmark {
      return accessSecureFileWithBookmark(bookmarkData: bookmarkData, operation: operation)
    }
    
    // Use first enabled data source
    if let firstSource = configuration.enabledDataSources.first,
       let bookmarkData = firstSource.fileBookmark {
      return accessSecureFileWithBookmark(bookmarkData: bookmarkData, operation: operation)
    }
    
    print("❌ No file bookmark available")
    return nil
  }
  
  func accessSecureFile<T>(dataSourceId: UUID, operation: (URL) throws -> T) -> T? {
    guard let source = configuration.dataSources.first(where: { $0.id == dataSourceId }),
          let bookmarkData = source.fileBookmark else {
      print("❌ No file bookmark available for data source")
      return nil
    }
    
    return accessSecureFileWithBookmark(bookmarkData: bookmarkData, operation: operation)
  }
  
  private func accessSecureFileWithBookmark<T>(bookmarkData: Data, operation: (URL) throws -> T) -> T? {
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
