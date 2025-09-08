//
//  SidebarView.swift
//  CodeTrack
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import SwiftUI

enum NavigationItem: String, CaseIterable {
    case general = "General"
    case thresholds = "Thresholds" 
    case info = "About"
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .thresholds: return "chart.bar"
        case .info: return "info.circle"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedItem: NavigationItem
    
    var body: some View {
        List(NavigationItem.allCases, id: \.self, selection: $selectedItem) { item in
            NavigationLink(value: item) {
                HStack {
                    Image(systemName: item.icon)
                        .foregroundColor(.primary)
                        .frame(width: 20)
                    
                    Text(item.rawValue)
                        .font(.system(size: 13))
                }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
        .padding(.vertical)
    }
}
