# ErdyTV

A modern macOS IPTV player built with SwiftUI and powered by VLC's MobileVLCKit for robust stream playback.

![macOS](https://img.shields.io/badge/macOS-26.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

### 🎯 Core Functionality
- **Universal Stream Support**: Powered by VLC's MobileVLCKit, supports virtually all IPTV stream formats (HLS, MPEG-TS, RTSP, etc.)
- **M3U Playlist Parsing**: Automatically parses M3U/M3U8 playlists with category grouping
- **Live & VOD Detection**: Automatically distinguishes between live streams and video-on-demand content
- **Fullscreen Mode**: Immersive viewing experience with auto-hiding controls

### 📺 Player Features
- **Seek Support**: Timeline scrubbing for VOD content
- **Playback Controls**: Play/pause, skip forward/backward (10s)
- **Volume Control**: Integrated volume slider
- **Auto-Hide Controls**: Controls fade out during playback for distraction-free viewing

### 🎨 User Interface
- **Category Management**: 
  - Filter categories with checkboxes
  - Reorder categories via drag-and-drop
  - Auto-expand selected channel's category
- **Channel Highlighting**: Currently playing channel is highlighted in the sidebar
- **Search**: Quick search across all channels
- **Responsive Design**: Clean, modern SwiftUI interface

### 💾 Persistence
- **Settings Storage**: All preferences saved to UserDefaults
- **Playlist URL**: Remembers your IPTV playlist URL
- **Category Preferences**: Saves visibility and order of categories
- **Session Restore**: Maintains your settings across app launches

## Screenshots

> Add screenshots of your app here

## Requirements

- macOS 26.0 or later
- Xcode 17.0 or later
- Swift 5.0 or later

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/erdyizm/ErdyTV.git
cd ErdyTV
```

2. Open the project in Xcode:
```bash
open ErdyTV.xcodeproj
```

3. Add the VLC dependency:
   - In Xcode, go to File → Add Package Dependencies
   - Enter: `https://github.com/omaralbeik/VLC.git`
   - Click "Add Package"

4. Build and run:
   - Select the ErdyTV scheme
   - Press `⌘ + R` to build and run

### Pre-built App

Download the latest release from the [Releases](https://github.com/erdyizm/ErdyTV/releases) page.

## Usage

1. **First Launch**: Enter your IPTV M3U playlist URL
2. **Browse Categories**: Use the sidebar to navigate through channel categories
3. **Watch**: Click on any channel to start playback
4. **Manage Categories**: 
   - Click the filter icon in the sidebar
   - Toggle category visibility
   - Click "Reorder" to drag categories into your preferred order
5. **Fullscreen**: Double-click the video player or use the fullscreen button

## Configuration

### Network Settings

The app is configured to allow arbitrary loads for IPTV streams. This is set in `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Sandbox Permissions

Network access is enabled in `ErdyTV.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

## Project Structure

```
ErdyTV/
├── ErdyTV/
│   ├── Models/
│   │   ├── M3UParser.swift          # M3U playlist parser
│   │   └── PlaylistManager.swift    # Playlist & settings manager
│   ├── ViewModels/
│   │   └── PlayerViewModel.swift    # VLC player logic
│   ├── Views/
│   │   ├── OnboardingView.swift     # Initial URL input
│   │   ├── MainPlayerView.swift     # Main app layout
│   │   ├── SidebarView.swift        # Category & channel list
│   │   ├── PlayerView.swift         # VLC video view
│   │   ├── VideoControlsView.swift  # Playback controls
│   │   └── AsyncImageView.swift     # Channel logo loader
│   ├── Assets.xcassets/             # App icon & assets
│   ├── Info.plist                   # App configuration
│   └── ErdyTV.entitlements          # Sandbox permissions
└── ErdyTV.xcodeproj/
```

## Dependencies

- [VLC](https://github.com/omaralbeik/VLC) - Swift wrapper for MobileVLCKit

## Known Issues

- Some channels may fail to load if they're offline or have invalid URLs
- Channel logos with invalid SSL certificates are handled gracefully

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Video playback powered by [VLC](https://www.videolan.org/)
- Icon design inspired by modern macOS aesthetics

## Author

**erdyizm** - [GitHub](https://github.com/erdyizm)

## Support

If you encounter any issues or have questions, please [open an issue](https://github.com/erdyizm/ErdyTV/issues).

---

Made with ❤️ for the IPTV community
