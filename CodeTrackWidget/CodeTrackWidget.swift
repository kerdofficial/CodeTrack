//
//  CodeTrackWidget.swift
//  CodeTrackWidget
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(
      date: Date(),
      usageDays: DataManager.shared.loadUsageData(),
      configuration: ConfigurationAppIntent()
    )
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
    SimpleEntry(
      date: Date(),
      usageDays: DataManager.shared.loadUsageData(),
      configuration: configuration
    )
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
    let currentDate = Date()
    let usageData = DataManager.shared.loadUsageData()
    let entry = SimpleEntry(date: currentDate, usageDays: usageData, configuration: configuration)

    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
    return Timeline(entries: [entry], policy: .after(nextUpdate))
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let usageDays: [UsageDay]
  let configuration: ConfigurationAppIntent
}

struct CodeTrackWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family

  var body: some View {
    Group {
      switch entry.configuration.viewType {
      case .grid:
        ContributionGridView(
          usageDays: entry.usageDays,
          daysToShow: entry.configuration.daysToShow,
          widgetFamily: family
        )
      case .chart:
        if family == .systemSmall {
          // Chart not available in small size, show grid instead
          ContributionGridView(
            usageDays: entry.usageDays,
            daysToShow: entry.configuration.daysToShow,
            widgetFamily: family
          )
        } else {
          ChartView(
            usageDays: entry.usageDays,
            widgetFamily: family
          )
        }
      }
    }
    .padding(4)
  }
}

struct CodeTrackWidget: Widget {
  let kind: String = "CodeTrackWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
      CodeTrackWidgetEntryView(entry: entry)
        .containerBackground(.background, for: .widget)
    }
    .configurationDisplayName("Code Usage")
    .description("Track your daily coding activity with grid or chart view")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
