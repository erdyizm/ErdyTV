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
                    let credits = NSMutableAttributedString(
                        string: "You can find the Source Code of the application from the following Git link: \n https://github.com/erdyizm/ErdyTV",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 11),
                            .foregroundColor: NSColor.labelColor
                        ]
                    )
                    let range = (credits.string as NSString).range(of: "https://github.com/erdyizm/ErdyTV")
                    credits.addAttribute(.link, value: "https://github.com/erdyizm/ErdyTV", range: range)
                    
                    NSApp.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: credits,
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
