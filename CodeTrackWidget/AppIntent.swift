//
//  AppIntent.swift
//  CodeTrackWidget
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import Foundation
import WidgetKit
import AppIntents

enum WidgetViewType: String, CaseIterable, AppEnum {
  case grid = "grid"
  case chart = "chart"
  
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "View Type"
  
  static var caseDisplayRepresentations: [WidgetViewType: DisplayRepresentation] = [
    .grid: "Grid View",
    .chart: "Chart View"
  ]
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Configuration"
  static var description = IntentDescription("Choose widget view type and settings.")
  
  @Parameter(title: "View Type", default: .grid)
  var viewType: WidgetViewType
  
  @Parameter(title: "Days to Show", default: 90)
  var daysToShow: Int
}
