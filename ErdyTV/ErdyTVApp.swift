//
//  ErdyTVApp.swift
//  ErdyTV
//
//  Created by Erdi on 23.11.2025.
//

import SwiftUI

@main
struct ErdyTVApp: App {
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
        }
    }
}
