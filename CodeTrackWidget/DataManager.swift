//
//  DataManager.swift
//  CodeTrackWidget
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import Foundation

struct AppConfiguration: Codable {
  var daysCount: DaysCount = .thirty

  enum DaysCount: Int, CaseIterable, Codable {
    case thirty = 30
    case sixty = 60
    case ninety = 90
  }
}

class DataManager {
  static let shared = DataManager()
  private init() {}

  private let appGroupIdentifier = "group.com.kerdofficial.CodeTrack"

  private var sharedFilePath: String? {
    guard
      let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    else {
      print("❌ CodeTrack: Failed to get App Group container URL")
      return nil
    }
    return containerURL.appendingPathComponent("codingTimeData.json").path
  }

  func loadUsageData() -> [UsageDay] {
    print("🔄 CodeTrack: Loading processed usage data from UserDefaults")
    print("🔍 CodeTrack: App Group Identifier: \(appGroupIdentifier)")

    if let containerURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    {
      print("✅ CodeTrack: App Group container accessible: \(containerURL.path)")
    } else {
      print("❌ CodeTrack: App Group container NOT accessible - check Xcode capabilities!")
    }

    guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
      print(
        "❌ CodeTrack: Failed to access shared UserDefaults - App Groups not properly configured")
      return generateEmptyDays()
    }

    print("✅ CodeTrack: SharedDefaults created successfully")

    if let processedData = sharedDefaults.data(forKey: "processedUsageData") {
      do {
        let decoder = JSONDecoder()
        let usageData = try decoder.decode([UsageDay].self, from: processedData)

        if let lastUpdate = sharedDefaults.object(forKey: "lastUpdateTime") as? Date {
          print(
            "✅ CodeTrack: Loaded \(usageData.count) days from UserDefaults (last updated: \(lastUpdate))"
          )
        } else {
          print("✅ CodeTrack: Loaded \(usageData.count) days from UserDefaults")
        }

        let activeDays = usageData.filter { $0.seconds > 0 }.count
        print("📈 CodeTrack: \(activeDays) days with activity")

        return usageData
      } catch {
        print("❌ CodeTrack: Error decoding UserDefaults data: \(error)")
      }
    } else {
      print("❌ CodeTrack: No processed data found in UserDefaults")
    }

    print("🔄 CodeTrack: Trying file-based data loading...")
    if let containerURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    {
      let fileURL = containerURL.appendingPathComponent("processed_usage_data.json")

      do {
        let fileData = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let usageData = try decoder.decode([UsageDay].self, from: fileData)

        print("✅ CodeTrack: Loaded \(usageData.count) days from shared file")
        let activeDays = usageData.filter { $0.seconds > 0 }.count
        print("📈 CodeTrack: \(activeDays) days with activity")

        return usageData
      } catch {
        print("❌ CodeTrack: Error reading shared file: \(error)")
      }
    }

    print("❌ CodeTrack: All data loading methods failed")
    return generateEmptyDays()
  }

  func getDaysToShow() -> Int {
    print("🔍 CodeTrack Widget: Loading configuration to get days count...")

    guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
      print("❌ CodeTrack Widget: Failed to create shared UserDefaults")
      return 30
    }

    print("✅ CodeTrack Widget: Shared UserDefaults created successfully")

    if let configData = sharedDefaults.data(forKey: "CodeTrackConfiguration") {
      print("✅ CodeTrack Widget: Found configuration data in shared UserDefaults")
      do {
        let decoder = JSONDecoder()
        let config = try decoder.decode(AppConfiguration.self, from: configData)
        print("✅ CodeTrack Widget: Decoded configuration - daysCount: \(config.daysCount.rawValue)")
        return config.daysCount.rawValue
      } catch {
        print("❌ CodeTrack Widget: Error decoding configuration: \(error)")
      }
    } else {
      print("❌ CodeTrack Widget: No configuration data found in shared UserDefaults")

      let allKeys = sharedDefaults.dictionaryRepresentation().keys
      print("🔍 CodeTrack Widget: Available keys in shared UserDefaults: \(Array(allKeys))")
    }

    print("⚠️ CodeTrack Widget: Using default 30 days")
    return 30
  }

  private func generateEmptyDays() -> [UsageDay] {
    let calendar = Calendar.current
    let today = Date()
    let daysToGenerate = getDaysToShow()

    var usageDays: [UsageDay] = []

    for dayOffset in (0..<daysToGenerate).reversed() {
      guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

      usageDays.append(
        UsageDay(
          date: date,
          seconds: 0,
          intensityLevel: .none,
          color: nil
        ))
    }

    return usageDays
  }
}
