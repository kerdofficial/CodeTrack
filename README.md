# CodeTrack 📊

> A sleek macOS menu bar application that transforms your coding activity into beautiful GitHub-style contribution visualizations

[![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org) [![macOS](https://img.shields.io/badge/macOS-15.0+-blue.svg)](https://www.apple.com/macos/) [![WidgetKit](https://img.shields.io/badge/WidgetKit-Compatible-green.svg)](https://developer.apple.com/documentation/widgetkit) [![App Version](https://img.shields.io/badge/App_Version-1.0.5-brightgreen.svg)](https://github.com/username/CodeTrack)

> [!IMPORTANT]
> ⚠️ **Early Phase Build** - CodeTrack is currently in active development with many exciting features planned for future releases!

## ✨ Features

### 🎯 Core Functionality

- **📈 Activity Visualization**: GitHub-style contribution grid showing your daily coding activity
- **🕒 Real-time Tracking**: Automatic synchronization with VSCode-based IDE's time tracking data
- **🎛️ Customizable Thresholds**: Fine-tune activity levels and colors to match your workflow
- **📱 Native macOS Widgets**: Beautiful system widgets in small and medium sizes
- **⚙️ Menu Bar Integration**: Lightweight, unobtrusive system presence

### 🎨 Personalization

- **🌈 Custom Color Schemes**: Personalize your activity visualization colors
- **📅 Flexible Timeframes**: View 30, 60, or 90 days of coding history
- **🎯 Activity Thresholds**: 5 customizable activity levels from "No Activity" to "Highest Activity"
- **🚀 System Integration**: Optional launch at system startup

### 📊 Data Insights

- **📂 Repository Tracking**: Monitor time spent across different projects
- **💻 Language Analytics**: See which programming languages you use most **- In Progress**
- **📄 File-level Details**: Detailed breakdown of time per file **- In Progress**
- **🔄 Auto-sync**: Hourly background synchronization with manual refresh option

## 🔧 Requirements

### Essential Setup

1. **VSCode-based IDE** with the [Time Extension](https://marketplace.visualstudio.com/items?itemName=n3rds-inc.time) installed
2. **macOS 15.0+** (Sequoia or later)
3. **Active coding in your IDE** to generate tracking data

### Prerequisites

- The Time extension must be installed and active in your VSCode-based IDE (VSCode, Cursor, etc.)
- Data is automatically saved to the IDE's global storage directory (e.g., `~/Library/Application Support/Cursor/User/globalStorage/n3rds-inc.time/codingTimeData.json`)
- CodeTrack reads this file to generate your activity visualization

## 🚀 Installation

1. **Download** the latest release from the releases page
2. **Install** CodeTrack.app to your Applications folder
3. **Launch** the application - it will appear in your menu bar
4. **Configure** your settings via the menu bar dropdown → "Open CodeTrack Settings"
5. **Set up** the data source path
6. **Add widgets** to your desktop from the widget gallery

## 📖 Usage

### Getting Started

1. Click the CodeTrack icon in your menu bar
2. Select "Open CodeTrack Settings" to configure the app
3. Verify the tracking data path points to your IDE's time tracking data
4. Choose your preferred display timeframe (30/60/90 days)
5. Customize activity thresholds and colors to your liking

### Widget Setup

1. Right-click on your desktop and select "Edit Widgets"
2. Search for "CodeTrack" in the widget gallery
3. Choose between Small or Medium widget sizes
4. Drag to your desired location on the desktop
5. Your coding activity will automatically appear!

### Syncing Data

- **Automatic**: CodeTrack syncs hourly in the background
- **Manual**: Use the "Sync Now" button in settings for immediate updates
- **Status Indicators**: Green checkmark for successful sync, red X for errors

## 🎛️ Configuration

### General Settings

- **System Integration**: Toggle launch at startup
- **Display Options**: Select timeframe (30/60/90 days)
- **Data Source**: Configure path to your IDE's time tracking data
- **Sync Status**: Monitor synchronization health

### Threshold Customization

- **No Activity** (0h): Gray, fixed color
- **Low Activity** (1h): Customizable light green
- **Medium Activity** (2h): Customizable medium green
- **High Activity** (4h): Customizable dark green
- **Highest Activity** (6h+): Customizable full green

Each threshold can be adjusted for both time duration and color representation.

## 🏗️ Architecture

### Technical Stack

- **SwiftUI**: Modern, declarative UI framework
- **WidgetKit**: Native macOS widget implementation
- **App Groups**: Secure data sharing between app and widgets
- **UserDefaults**: Configuration persistence
- **FileManager**: Secure file system access

### Key Components

- **DataManager**: Handles IDE data synchronization
- **ConfigurationManager**: Manages app settings and preferences
- **ContributionGridView**: GitHub-style activity visualization
- **LoginItemManager**: System startup integration
- **Widget Timeline Provider**: Manages widget update cycles

## 🔮 Roadmap

CodeTrack is in active development! Upcoming features include:

- 📊 Enhanced analytics and insights
- 🔄 Multi-IDE support beyond Cursor
- 📈 Detailed reporting and export options
- 🎨 Additional visualization styles
- ⚡ Performance optimizations

## 🤝 Contributing

We welcome contributions! Whether it's bug reports, feature requests, or code contributions, your input helps make CodeTrack better.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **n3rds-inc** for the Time extension that makes this integration possible
