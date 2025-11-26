//
//  ContentView.swift
//  ErdyTV
//
//  Created by Erdi on 23.11.2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var playlistManager: PlaylistManager
    
    var body: some View {
        Group {
            if playlistManager.savedURL != nil {
                MainPlayerView(playlistManager: playlistManager)
            } else {
                OnboardingView(playlistManager: playlistManager)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            playlistManager.loadPlaylist()
        }
    }
}

#Preview {
    ContentView(playlistManager: PlaylistManager())
}
