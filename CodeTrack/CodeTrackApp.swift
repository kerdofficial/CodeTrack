//
//  CodeTrackApp.swift
//  CodeTrack
//
//  Created by Dániel Kerekes on 2025. 09. 07..
//

import SwiftUI

@main
struct CodeTrackApp: App {
  @StateObject private var appState = AppState()

  var body: some Scene {
    MenuBarExtra("CodeTrack", systemImage: "square.grid.3x3.square") {
        SettingsMenuContent()
          .environmentObject(appState)
    }
    .menuBarExtraStyle(.menu)

    WindowGroup("CodeTrack Settings", id: "settings") {
      ContentView()
        .environmentObject(appState)
        .frame(
          minWidth: 1200, maxWidth: 1200,
          minHeight: 700, maxHeight: 700)
    }
    .windowResizability(.contentSize)
    .defaultPosition(.center)
    .windowStyle(.titleBar)
    .commands {
      CommandGroup(replacing: .newItem) {}
    }
  }
}

struct SettingsMenuContent: View {
  @Environment(\.openWindow) private var openWindow
  @EnvironmentObject var appState: AppState
  
  var body: some View {
    Button("Open CodeTrack Settings") {
      openWindow(id: "settings")
      appState.isSettingsWindowOpen = true
    }
    
    Divider()
    
    Button("Quit") {
      NSApplication.shared.terminate(nil)
    }
  }
}

class AppState: ObservableObject {
  @Published var isSettingsWindowOpen = false

  func openSettings() {
    isSettingsWindowOpen = true
    NSApp.activate(ignoringOtherApps: true)
    
    // Try to find existing window first
    if let window = NSApp.windows.first(where: { $0.title == "CodeTrack Settings" }) {
      window.makeKeyAndOrderFront(nil)
    }
  }

  func closeSettings() {
    isSettingsWindowOpen = false
  }
}
