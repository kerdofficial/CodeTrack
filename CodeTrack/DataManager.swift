//
//  DataManager.swift
//  CodeTrack
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import Foundation

class DataManager {
  static let shared = DataManager()
  private init() {}

  private let appGroupIdentifier = "group.com.kerdofficial.CodeTrack"
  private var originalFilePath = {
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
    return
      "\(homeDirectory)/Library/Application Support/Cursor/User/globalStorage/n3rds-inc.time/codingTimeData.json"
  }()

  func updateFilePath(_ newPath: String) {
    originalFilePath = newPath
    print("📁 CodeTrack: Updated file path to \(newPath)")
  }

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

  private var sharedUserDefaults: UserDefaults? {
    return UserDefaults(suiteName: appGroupIdentifier)
  }

  func copyOriginalDataToSharedContainer() -> Bool {
    let configManager = ConfigurationManager()
    let enabledSources = configManager.configuration.enabledDataSources
    
    guard !enabledSources.isEmpty else {
      print("⚠️ CodeTrack: No enabled data sources")
      return false
    }
    
    print("📊 CodeTrack: Processing \(enabledSources.count) data source(s)")
    
    var allCodingData: [CodingTimeData] = []
    var successCount = 0
    
    // Load data from all enabled sources
    for source in enabledSources {
      print("📂 CodeTrack: Loading data from '\(source.name)'")
      
      if let result = configManager.accessSecureFile(dataSourceId: source.id, operation: { url -> CodingTimeData? in
        do {
          let data = try Data(contentsOf: url)
          let codingData = try JSONDecoder().decode(CodingTimeData.self, from: data)
          print("✅ CodeTrack: Successfully loaded data from '\(source.name)'")
          return codingData
        } catch {
          print("❌ CodeTrack: Error reading data from '\(source.name)': \(error)")
          return nil
        }
      }), let codingData = result {
        allCodingData.append(codingData)
        successCount += 1
      }
    }
    
    guard successCount > 0 else {
      print("❌ CodeTrack: Failed to load data from any source")
      return false
    }
    
    print("✅ CodeTrack: Successfully loaded data from \(successCount)/\(enabledSources.count) source(s)")
    
    // Merge all data sources
    let mergedData = mergeCodingTimeData(allCodingData)
    return processAndStoreData(mergedData)
  }
  
  private func mergeCodingTimeData(_ dataArray: [CodingTimeData]) -> CodingTimeData {
    guard !dataArray.isEmpty else {
      return CodingTimeData(dailyData: [:])
    }
    
    if dataArray.count == 1 {
      return dataArray[0]
    }
    
    print("🔄 CodeTrack: Merging \(dataArray.count) data sources")
    
    var mergedDailyData: [String: DailyUsage] = [:]
    
    // Merge all daily data
    for codingData in dataArray {
      for (dateKey, dailyUsage) in codingData.dailyData {
        if let existing = mergedDailyData[dateKey] {
          // Merge with existing data for this date
          let mergedTotalTime = existing.totalTime + dailyUsage.totalTime
          
          // Merge language times
          var mergedLanguageTime = existing.languageTime ?? [:]
          if let languageTime = dailyUsage.languageTime {
            for (lang, time) in languageTime {
              mergedLanguageTime[lang, default: 0] += time
            }
          }
          
          // Merge repo times
          var mergedRepoTime = existing.repoTime ?? [:]
          if let repoTime = dailyUsage.repoTime {
            for (repo, time) in repoTime {
              mergedRepoTime[repo, default: 0] += time
            }
          }
          
          // Merge file times
          var mergedFileTime = existing.fileTime ?? [:]
          if let fileTime = dailyUsage.fileTime {
            for (file, time) in fileTime {
              mergedFileTime[file, default: 0] += time
            }
          }
          
          mergedDailyData[dateKey] = DailyUsage(
            totalTime: mergedTotalTime,
            languageTime: mergedLanguageTime.isEmpty ? nil : mergedLanguageTime,
            repoTime: mergedRepoTime.isEmpty ? nil : mergedRepoTime,
            fileTime: mergedFileTime.isEmpty ? nil : mergedFileTime
          )
        } else {
          // First entry for this date
          mergedDailyData[dateKey] = dailyUsage
        }
      }
    }
    
    print("✅ CodeTrack: Merged data contains \(mergedDailyData.count) days")
    
    return CodingTimeData(dailyData: mergedDailyData)
  }

  private func processAndStoreData(_ codingData: CodingTimeData) -> Bool {
    do {

      let usageData = processUsageData(codingData)

      var success = false

      if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
        let encoder = JSONEncoder()
        let processedData = try encoder.encode(usageData)

        sharedDefaults.set(processedData, forKey: "processedUsageData")
        sharedDefaults.set(Date(), forKey: "lastUpdateTime")
        sharedDefaults.synchronize()

        print("✅ CodeTrack: Stored in UserDefaults")
        success = true
      }

      if let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupIdentifier)
      {
        let fileURL = containerURL.appendingPathComponent("processed_usage_data.json")
        let encoder = JSONEncoder()
        let processedData = try encoder.encode(usageData)

        try processedData.write(to: fileURL)
        print("✅ CodeTrack: Stored in shared file: \(fileURL.path)")
        success = true
      }

      if success {
        print("📊 CodeTrack: Stored \(usageData.count) days of data")
        let activeDays = usageData.filter { $0.seconds > 0 }.count
        print("📈 CodeTrack: \(activeDays) days with activity")
        return true
      } else {
        print("❌ CodeTrack: Failed all storage methods")
        return false
      }

    } catch {
      print("❌ CodeTrack: Error encoding/storing data: \(error)")
      return false
    }
  }

  private func processUsageData(_ codingData: CodingTimeData) -> [UsageDay] {
    let config = loadConfiguration()
    let daysCount = config.daysCount.rawValue
    let thresholds = config.thresholds

    let calendar = Calendar.current
    let today = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    var usageDays: [UsageDay] = []
    print("📅 CodeTrack: Processing last \(daysCount) days of data")

    for dayOffset in (0..<daysCount).reversed() {
      guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
      let dateString = dateFormatter.string(from: date)

      let seconds = codingData.dailyData[dateString]?.totalTime ?? 0
      let intensity = getIntensityLevel(for: seconds, thresholds: thresholds)

      if seconds > 0 {
        let hours = Double(seconds) / 3600.0
        print(
          "📊 CodeTrack: \(dateString): \(seconds)s (\(String(format: "%.1f", hours))h) - \(intensity)"
        )
      }

      let matchingThreshold = thresholds.sorted { $0.seconds < $1.seconds }
        .last { $0.seconds <= seconds }
      let color = matchingThreshold?.color

      usageDays.append(
        UsageDay(
          date: date,
          seconds: seconds,
          intensityLevel: intensity,
          color: color
        ))
    }

    return usageDays
  }

  private func loadConfiguration() -> AppConfiguration {
    if let data = UserDefaults.standard.data(forKey: "CodeTrackConfiguration") {
      do {
        return try JSONDecoder().decode(AppConfiguration.self, from: data)
      } catch {
        print("❌ Error loading configuration from standard UserDefaults: \(error)")
      }
    }

    if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
      let data = sharedDefaults.data(forKey: "CodeTrackConfiguration")
    {
      do {
        return try JSONDecoder().decode(AppConfiguration.self, from: data)
      } catch {
        print("❌ Error loading configuration from shared UserDefaults: \(error)")
      }
    }

    print("ℹ️ No configuration found, using defaults")
    return AppConfiguration()
  }

  private func getIntensityLevel(for seconds: Int, thresholds: [Threshold]) -> IntensityLevel {
    let sortedThresholds = thresholds.sorted { $0.seconds < $1.seconds }

    for threshold in sortedThresholds.reversed() {
      if seconds >= threshold.seconds {
        return threshold.seconds == 0
          ? .none
          : threshold.seconds < 3600
            ? .low
            : threshold.seconds < 7200 ? .medium : threshold.seconds < 14400 ? .high : .highest
      }
    }

    return .none
  }

  func startPeriodicDataSync() {
    _ = copyOriginalDataToSharedContainer()

    Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
      print("⏰ CodeTrack: Performing scheduled data sync")
      _ = self.copyOriginalDataToSharedContainer()
    }
  }
}
