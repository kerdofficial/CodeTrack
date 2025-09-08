//
//  ContentView.swift
//  CodeTrack
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import SwiftUI

struct ContentView: View {
  @StateObject private var configManager = ConfigurationManager()
  @EnvironmentObject var appState: AppState
  @State private var selectedNavItem: NavigationItem = .general

  var body: some View {
    NavigationSplitView {
      SidebarView(selectedItem: $selectedNavItem)
        .navigationTitle("")
        .toolbar(.hidden)
    } detail: {
      Group {
        switch selectedNavItem {
        case .general:
          GeneralSettingsView(configManager: configManager)
        case .thresholds:
          ThresholdsSettingsView(configManager: configManager)
        case .info:
          InfoView()
        }
      }
      .frame(minWidth: 900, minHeight: 700)
    }
    .navigationSplitViewColumnWidth(min: 200, ideal: 200)
  }

}

#Preview {
  ContentView()
}
