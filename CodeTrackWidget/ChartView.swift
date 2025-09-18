//
//  ChartView.swift
//  CodeTrackWidget
//
//  Created by Dániel Kerekes on 2025. 09. 12..
//

import SwiftUI
import WidgetKit

struct ChartView: View {
  let usageDays: [UsageDay]
  let widgetFamily: WidgetFamily
  
  private let chartDays = 30
  
  var body: some View {
    GeometryReader { geometry in
      let chartData = getChartData()
      let maxHours = getMaxHours(from: chartData)
      let padding: CGFloat = 16
      let availableWidth = geometry.size.width - (padding * 2)
      let availableHeight = geometry.size.height - (padding * 2)
      
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Coding Hours (Last 30 Days)")
            .font(.caption)
            .fontWeight(.medium)
          Spacer()
          if maxHours > 0 {
            Text("\(Int(maxHours))h max")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
        
        ZStack {
          // Chart background
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.1))
          
          // Chart content
          VStack(spacing: 0) {
            // Chart bars
            HStack(alignment: .bottom, spacing: 1) {
              ForEach(0..<chartDays, id: \.self) { dayIndex in
                let dayData = chartData[dayIndex]
                let barHeight = maxHours > 0 ? (dayData.hours / maxHours) * (availableHeight - 40) : 0
                
                VStack(spacing: 0) {
                  Spacer()
                  RoundedRectangle(cornerRadius: 2)
                    .fill(getBarColor(for: dayData))
                    .frame(height: max(2, barHeight))
                }
              }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            // X-axis labels (show only some days)
            HStack {
              ForEach(0..<chartDays, id: \.self) { dayIndex in
                if shouldShowLabel(for: dayIndex) {
                  Text(getDateLabel(for: dayIndex))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                } else {
                  Text("")
                    .font(.caption2)
                }
              }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
          }
        }
        .frame(height: availableHeight)
      }
      .padding(padding)
    }
  }
  
  private func getChartData() -> [ChartDataPoint] {
    let calendar = Calendar.current
    let today = Date()
    
    var chartData: [ChartDataPoint] = []
    
    for dayIndex in 0..<chartDays {
      guard let date = calendar.date(byAdding: .day, value: -(chartDays - 1 - dayIndex), to: today) else {
        chartData.append(ChartDataPoint(date: today, hours: 0, intensityLevel: .none))
        continue
      }
      
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
      let targetDateString = dateFormatter.string(from: date)
      
      var found = false
      for usageDay in usageDays {
        let usageDayString = dateFormatter.string(from: usageDay.date)
        if usageDayString == targetDateString {
          let hours = Double(usageDay.seconds) / 3600.0
          chartData.append(ChartDataPoint(date: date, hours: hours, intensityLevel: usageDay.intensityLevel))
          found = true
          break
        }
      }
      
      if !found {
        chartData.append(ChartDataPoint(date: date, hours: 0, intensityLevel: .none))
      }
    }
    
    return chartData
  }
  
  private func getMaxHours(from chartData: [ChartDataPoint]) -> Double {
    let maxHours = chartData.map { $0.hours }.max() ?? 0
    return max(1, maxHours) // Ensure minimum scale of 1 hour
  }
  
  private func getBarColor(for dataPoint: ChartDataPoint) -> Color {
    switch dataPoint.intensityLevel {
    case .none: return Color.gray.opacity(0.3)
    case .low: return Color.green.opacity(0.4)
    case .medium: return Color.green.opacity(0.6)
    case .high: return Color.green.opacity(0.8)
    case .highest: return Color.green
    }
  }
  
  private func shouldShowLabel(for dayIndex: Int) -> Bool {
    switch widgetFamily {
    case .systemMedium:
      return dayIndex % 5 == 0 || dayIndex == chartDays - 1
    case .systemLarge:
      return dayIndex % 3 == 0 || dayIndex == chartDays - 1
    default:
      return false
    }
  }
  
  private func getDateLabel(for dayIndex: Int) -> String {
    let calendar = Calendar.current
    let today = Date()
    
    guard let date = calendar.date(byAdding: .day, value: -(chartDays - 1 - dayIndex), to: today) else {
      return ""
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "M/d"
    return formatter.string(from: date)
  }
}

struct ChartDataPoint {
  let date: Date
  let hours: Double
  let intensityLevel: IntensityLevel
}