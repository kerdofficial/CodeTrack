//
//  ThresholdsSettingsView.swift
//  CodeTrack
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import SwiftUI
import WidgetKit

struct ThresholdsSettingsView: View {
  @ObservedObject var configManager: ConfigurationManager
  @State private var hasUnsavedChanges = false
  @State private var originalThresholds: [Threshold] = []

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Activity Thresholds")
              .font(.title2)
              .fontWeight(.semibold)

            Text("Configure how different activity levels are displayed in the widget.")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          VStack(spacing: 16) {
            ForEach(Array(configManager.configuration.thresholds.enumerated()), id: \.offset) {
              index, threshold in
              ThresholdRow(
                threshold: $configManager.configuration.thresholds[index],
                onChanged: {
                  checkForChanges()
                }
              )
            }
          }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      VStack {
        Divider()

        HStack(spacing: 12) {
          Spacer()

          Button("Save Changes") {
            saveChanges()
          }
          .buttonStyle(.borderedProminent)
          .disabled(!hasUnsavedChanges)

          Button("Reset to Defaults") {
            resetToDefaults()
          }
          .buttonStyle(.bordered)
        }
        .padding()
        .padding(.top, 0)
      }
    }
    .onAppear {
      originalThresholds = configManager.configuration.thresholds
      hasUnsavedChanges = false
    }
  }

  private func checkForChanges() {
    hasUnsavedChanges = !thresholdsAreEqual(
      configManager.configuration.thresholds, originalThresholds)
  }

  private func thresholdsAreEqual(_ lhs: [Threshold], _ rhs: [Threshold]) -> Bool {
    guard lhs.count == rhs.count else { return false }

    for (index, threshold) in lhs.enumerated() {
      let original = rhs[index]
      if threshold.seconds != original.seconds || threshold.color.red != original.color.red
        || threshold.color.green != original.color.green
        || threshold.color.blue != original.color.blue
        || threshold.color.alpha != original.color.alpha
      {
        return false
      }
    }
    return true
  }

  private func saveChanges() {
    configManager.saveConfiguration()
    DataManager.shared.copyOriginalDataToSharedContainer()
    originalThresholds = configManager.configuration.thresholds
    hasUnsavedChanges = false
    
    // Refresh widgets after saving threshold changes
    WidgetCenter.shared.reloadAllTimelines()
  }

  private func resetToDefaults() {
    configManager.configuration.thresholds = Threshold.defaultThresholds
    checkForChanges()
    saveChanges()
  }
}

struct ThresholdRow: View {
  @Binding var threshold: Threshold
  let onChanged: () -> Void

  @State private var hours: Double = 0
  @State private var showingColorPicker = false

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 12) {
        Button {
          if threshold.isEditable {
            showingColorPicker.toggle()
          }
        } label: {
          RoundedRectangle(cornerRadius: 4)
            .fill(threshold.color.color)
            .frame(width: 32, height: 32)
            .overlay(
              RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!threshold.isEditable)
        .popover(isPresented: $showingColorPicker, attachmentAnchor: .point(.top)) {
          ColorPicker(
            "Choose color",
            selection: Binding(
              get: { threshold.color.color },
              set: { newColor in
                threshold.color = CodableColor(newColor)
                onChanged()
              }
            )
          )
          .padding()
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(threshold.displayName)
            .font(.system(size: 14, weight: .medium))

          Text(threshold.isEditable ? "Adjustable" : "Fixed")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        Text(String(format: "%.1fh", hours))
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.primary)
          .frame(minWidth: 40, alignment: .trailing)
      }

      if threshold.isEditable {
        HStack(spacing: 8) {
          Text("0h")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(width: 20, alignment: .trailing)

          Slider(
            value: Binding(
              get: { hours },
              set: { newValue in
                hours = newValue
                threshold.seconds = Int(newValue * 3600)
                onChanged()
              }
            ), in: 0...12, step: 0.5
          )
          .accentColor(threshold.color.color)

          Text("12h")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(width: 20)
        }
        .padding(.leading, 44)
      }
    }
    .padding(.vertical, 8)
    .onChange(of: threshold.seconds) { _ in
      hours = Double(threshold.seconds) / 3600.0
    }
    .onAppear {
      hours = Double(threshold.seconds) / 3600.0
    }
  }
}
