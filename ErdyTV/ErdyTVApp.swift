//
//  ErdyTVApp.swift
//  ErdyTV
//
//  Created by Erdi on 23.11.2025.
//

import SwiftUI

@main
struct ErdyTVApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var playlistManager = PlaylistManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(playlistManager: playlistManager)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Change Playlist URL...") {
                    playlistManager.clearPlaylist()
                }
            }
            
            CommandGroup(replacing: .appInfo) {
                Button("About ErdyTV") {
                    NSApp.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "Source Code: https://github.com/erdyizm/ErdyTV",
                                attributes: [
                                    .font: NSFont.systemFont(ofSize: 11),
                                    .foregroundColor: NSColor.labelColor
                                ]
                            ),
                            NSApplication.AboutPanelOptionKey.applicationName: "ErdyTV"
                        ]
                    )
                }
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force windowed mode on launch
        DispatchQueue.main.async {
            for window in NSApp.windows {
                if window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
