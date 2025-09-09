//
//  ContributionGridView.swift
//  CodeTrackWidget
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import SwiftUI
import WidgetKit

struct ContributionGridView: View {
  let usageDays: [UsageDay]
  let daysToShow: Int
  let widgetFamily: WidgetFamily

  var body: some View {
    GeometryReader { geometry in
      let totalWidth = geometry.size.width
      let totalHeight = geometry.size.height

      let totalDays = getOptimalDaysCount()
      let aspectRatio = totalWidth / totalHeight

      let (rows, cols) = calculateOptimalGrid(totalDays: totalDays, aspectRatio: aspectRatio)

      let horizontalSpacing: CGFloat = 3
      let verticalSpacing: CGFloat = 3

      let availableWidth = totalWidth - (CGFloat(cols - 1) * horizontalSpacing)
      let availableHeight = totalHeight - (CGFloat(rows - 1) * verticalSpacing)

      let cellWidth = availableWidth / CGFloat(cols)
      let cellHeight = availableHeight / CGFloat(rows)

      VStack(alignment: .leading, spacing: verticalSpacing) {
        ForEach(0..<rows, id: \.self) { rowIndex in
          HStack(spacing: horizontalSpacing) {
            let colsInThisRow =
              (rowIndex == rows - 1) ? min(totalDays - rowIndex * cols, cols) : cols

            ForEach(0..<colsInThisRow, id: \.self) { colIndex in
              let dayIndex = rowIndex * cols + colIndex
              if dayIndex < totalDays {
                let dayData = getDayData(for: dayIndex)
                RoundedRectangle(cornerRadius: 4)
                  .fill(dayData.color?.color ?? getDefaultColor(for: dayData.intensityLevel))
                  .frame(width: cellWidth, height: cellHeight)
                  .overlay(
                    RoundedRectangle(cornerRadius: 4)
                      .stroke(
                        Color.primary.opacity(0.15),
                        lineWidth: 0)
                  )
              }
            }

            if colsInThisRow < cols {
              Spacer()
            }
          }
        }
      }
      .frame(width: totalWidth, height: totalHeight, alignment: .topLeading)
    }
  }

  private func calculateOptimalGrid(totalDays: Int, aspectRatio: CGFloat) -> (rows: Int, cols: Int)
  {
    var bestRows = 1
    var bestCols = totalDays
    var bestDiff = CGFloat.greatestFiniteMagnitude

    let maxRows = min(totalDays, Int(sqrt(Double(totalDays)) * 2))

    for rows in 1...maxRows {
      let cols = Int(ceil(Double(totalDays) / Double(rows)))

      guard rows * cols >= totalDays else { continue }

      let gridRatio = CGFloat(cols) / CGFloat(rows)
      let diff = abs(gridRatio - aspectRatio)

      if diff < bestDiff {
        bestDiff = diff
        bestRows = rows
        bestCols = cols
      }
    }

    return (bestRows, bestCols)
  }

  private func getOptimalDaysCount() -> Int {
    switch widgetFamily {
    case .systemSmall:
      return min(daysToShow, 49) // 7x7 maximum
    case .systemMedium:
      return min(daysToShow, 91) // ~13x7 maximum
    case .systemLarge:
      return daysToShow // Show all days
    default:
      return daysToShow
    }
  }

  private func getDayData(for dayIndex: Int) -> UsageDay {
    let calendar = Calendar.current
    let today = Date()
    let totalDays = getOptimalDaysCount()

    guard
      let targetDate = calendar.date(byAdding: .day, value: -(totalDays - 1 - dayIndex), to: today)
    else {
      return UsageDay(date: today, seconds: 0, intensityLevel: .none)
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let targetDateString = dateFormatter.string(from: targetDate)

    for usageDay in usageDays {
      let usageDayString = dateFormatter.string(from: usageDay.date)
      if usageDayString == targetDateString {
        return usageDay
      }
    }

    return UsageDay(date: targetDate, seconds: 0, intensityLevel: .none)
  }

  private func getDefaultColor(for intensity: IntensityLevel) -> Color {
    switch intensity {
    case .none: return Color.gray.opacity(0.3)
    case .low: return Color.green.opacity(0.3)
    case .medium: return Color.green.opacity(0.5)
    case .high: return Color.green.opacity(0.7)
    case .highest: return Color.green
    }
  }

}
