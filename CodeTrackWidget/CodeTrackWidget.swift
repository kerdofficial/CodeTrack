//
//  CodeTrackWidget.swift
//  CodeTrackWidget
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(
      date: Date(),
      usageDays: DataManager.shared.loadUsageData(),
      daysToShow: DataManager.shared.getDaysToShow()
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    let entry = SimpleEntry(
      date: Date(),
      usageDays: DataManager.shared.loadUsageData(),
      daysToShow: DataManager.shared.getDaysToShow()
    )
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
    let currentDate = Date()
    let usageData = DataManager.shared.loadUsageData()
    let daysCount = DataManager.shared.getDaysToShow()
    let entry = SimpleEntry(date: currentDate, usageDays: usageData, daysToShow: daysCount)

    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let usageDays: [UsageDay]
  let daysToShow: Int
}

struct CodeTrackWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family

  var body: some View {
    ContributionGridView(
      usageDays: entry.usageDays,
      daysToShow: entry.daysToShow,
      widgetFamily: family
    )
    .padding(4)
  }
}

struct CodeTrackWidget: Widget {
  let kind: String = "CodeTrackWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      CodeTrackWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Code Usage")
    .description("Track your daily coding activity")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
