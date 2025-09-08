//
//  GeneralSettingsView.swift
//  CodeTrack
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import SwiftUI
import WidgetKit

struct GeneralSettingsView: View {
  @ObservedObject var configManager: ConfigurationManager
  @State private var syncStatus = "Ready"
  @State private var lastSyncTime: Date?
  @State private var showingFirstLaunchAlert = false

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        GroupBox("System Integration") {
          HStack {
            Text("Start with system")
            Spacer()
            Toggle(
              "",
              isOn: Binding(
                get: { LoginItemManager.shared.isEnabledAsLoginItem },
                set: { LoginItemManager.shared.isEnabledAsLoginItem = $0 }
              )
            )
            .labelsHidden()
            .toggleStyle(.switch)
          }
          .padding()
        }
        .frame(maxWidth: .infinity)

        GroupBox("Display Options") {
          VStack(spacing: 12) {
            HStack {
              Text("Days to show:")
                .frame(maxWidth: .infinity, alignment: .leading)
              Picker("", selection: $configManager.configuration.daysCount) {
                ForEach(AppConfiguration.DaysCount.allCases, id: \.self) { days in
                  Text(days.displayName).tag(days)
                }
              }
              .labelsHidden()
              .pickerStyle(.menu)
              .frame(width: 120)
            }
          }
          .padding()
        }
        .onChange(of: configManager.configuration.daysCount) { _ in
          configManager.saveConfiguration()
          performSync()
          WidgetCenter.shared.reloadAllTimelines()
        }

        GroupBox("Data Source") {
          VStack(spacing: 12) {
            HStack {
              Text("Tracking Data Path:")
                .font(.headline)
              Spacer()
            }

            if configManager.configuration.isFirstLaunch {
              VStack(spacing: 8) {
                Text("⚠️ Setup Required")
                  .font(.headline)
                  .foregroundColor(.orange)

                Text("Please select your time tracking data file to get started.")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .multilineTextAlignment(.center)

                Button("Select Time Data File") {
                  showFilePicker()
                }
                .buttonStyle(.borderedProminent)
              }
              .padding()
              .background(Color.orange.opacity(0.1))
              .cornerRadius(8)
            } else {
              VStack(spacing: 8) {
                HStack {
                  TextField("File path", text: $configManager.configuration.filePath)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)

                  Button("Change...") {
                    showFilePicker()
                  }
                  .buttonStyle(.bordered)
                }

                Text("✅ File access configured")
                  .font(.caption)
                  .foregroundColor(.green)
              }
            }

            Text(
              "Note: Select the codingTimeData.json file from your VSCode/Cursor time extension directory."
            )
            .font(.caption)
            .foregroundColor(.secondary)
          }
          .padding()
        }

        GroupBox("Sync Status") {
          VStack(spacing: 12) {
            HStack {
              Text("Status:")
              Spacer()
              HStack(spacing: 6) {
                if syncStatus.contains("✅") {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                  Text("Sync successful")
                    .foregroundColor(.green)
                } else if syncStatus.contains("❌") {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                  Text("Sync failed")
                    .foregroundColor(.red)
                } else if syncStatus == "Syncing..." {
                  ProgressView()
                    .scaleEffect(0.4)
                  Text("Syncing...")
                    .foregroundColor(.blue)
                } else {
                  Text(syncStatus)
                    .foregroundColor(.secondary)
                }
              }
              .font(.system(size: 13, weight: .medium))
            }

            if let lastSync = lastSyncTime {
              HStack {
                Text("Last sync:")
                Spacer()
                Text(formatter(date: lastSync))
                  .foregroundColor(.secondary)
              }
            }

            HStack {
              Spacer()
              Button("Sync Now") {
                performSync()
              }
              .buttonStyle(.borderedProminent)
              .disabled(syncStatus == "Syncing...")
            }
          }
          .padding()
        }

        Text(
          "If you see that file access was successful, but the sync still fails, please try selecting the file again. This is a known issue with the file access mechanism, and we are working on a solution. If you encounter this issue, please open an issue on GitHub for the matter."
        )
        .font(.caption)
        .foregroundColor(.yellow)
        .multilineTextAlignment(.center)

        Spacer()
      }
      .padding(24)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      startDataSync()
    }
    .onChange(of: configManager.configuration.isFirstLaunch) { _ in
      DispatchQueue.main.async {
      }
    }
  }

  private func formatter(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .short
    dateFormatter.locale = Locale(identifier: "en_US")
    return dateFormatter.string(from: date)
  }

  private func startDataSync() {
    if !configManager.configuration.filePath.isEmpty {
      DataManager.shared.updateFilePath(configManager.configuration.filePath)
      DataManager.shared.startPeriodicDataSync()
      performSync()
    } else if !configManager.configuration.isFirstLaunch {
      performSync()
    }
  }

  private func performSync() {
    syncStatus = "Syncing..."

    DispatchQueue.global(qos: .background).async {
      let success = DataManager.shared.copyOriginalDataToSharedContainer()

      DispatchQueue.main.async {
        if success {
          syncStatus = "✅ Sync successful"
          lastSyncTime = Date()

          WidgetCenter.shared.reloadAllTimelines()
        } else {
          syncStatus = "❌ Sync failed"
        }
      }
    }
  }

  private func showFilePicker() {
    let panel = NSOpenPanel()
    panel.title = "Select Time Tracking Data File"
    panel.message =
      "Select the codingTimeData.json file from your VSCode/Cursor extension directory"
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = [.json]

    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
    let commonPaths = [
      "Library/Application Support/Cursor/User/globalStorage/n3rds-inc.time",
      "Library/Application Support/Code/User/globalStorage/n3rds-inc.time",
      ".vscode/globalStorage/n3rds-inc.time",
    ]

    for path in commonPaths {
      let fullPath = homeDirectory.appendingPathComponent(path)
      if FileManager.default.fileExists(atPath: fullPath.path) {
        panel.directoryURL = fullPath
        break
      }
    }

    panel.begin { [weak configManager] response in
      guard response == .OK, let url = panel.url, let configManager = configManager else { return }

      print("🔄 File selected: \(url.path)")
      
      guard url.startAccessingSecurityScopedResource() else {
        print("❌ Failed to start accessing security-scoped resource")
        return
      }

      print("✅ Security-scoped resource access started")

      defer {
        url.stopAccessingSecurityScopedResource()
        print("🔄 Security-scoped resource access stopped")
      }

      do {
        let testData = try Data(contentsOf: url)
        print("✅ File read test successful, size: \(testData.count) bytes")
      } catch {
        print("❌ File read test failed: \(error)")
        return
      }

      configManager.saveFileBookmark(for: url)

      DataManager.shared.updateFilePath(url.path)

      performSync()

      WidgetCenter.shared.reloadAllTimelines()
    }
  }
}

extension DateFormatter {
  static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
  }()
}
