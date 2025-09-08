//
//  CodingTimeData.swift
//  CodeTrackWidget
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import Foundation

struct CodingTimeData: Codable {
    let dailyData: [String: DailyUsage]
    
    private enum CodingKeys: String, CodingKey {
        case dailyData
    }
}

struct DailyUsage: Codable {
    let totalTime: Int
    let languageTime: [String: Int]?
    let repoTime: [String: Int]?
    let fileTime: [String: Int]?
    
    private enum CodingKeys: String, CodingKey {
        case totalTime
        case languageTime  
        case repoTime
        case fileTime
    }
}

