//
//  UsageDay.swift
//  CodeTrackWidget
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import Foundation

struct UsageDay: Codable {
    let date: Date
    let seconds: Int
    let intensityLevel: IntensityLevel
    let color: CodableColor?
    
    init(date: Date, seconds: Int, intensityLevel: IntensityLevel, color: CodableColor? = nil) {
        self.date = date
        self.seconds = seconds
        self.intensityLevel = intensityLevel
        self.color = color
    }
}

enum IntensityLevel: String, CaseIterable, Codable {
    case none      = "none"
    case low       = "low"
    case medium    = "medium"
    case high      = "high"
    case highest   = "highest"
    
    var opacity: Double {
        switch self {
        case .none: return 0.0
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.7
        case .highest: return 1.0
        }
    }
    
    static func from(seconds: Int) -> IntensityLevel {
        let hours = Double(seconds) / 3600.0
        
        if hours == 0 { return .none }
        else if hours < 1 { return .low }
        else if hours < 2 { return .medium }
        else if hours < 4 { return .high }
        else { return .highest }
    }
}