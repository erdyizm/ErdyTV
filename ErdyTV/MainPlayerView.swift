import SwiftUI

struct MainPlayerView: View {
    @ObservedObject var playlistManager: PlaylistManager
    @StateObject private var playerViewModel = PlayerViewModel()
    @State private var selectedChannel: Channel?
    @State private var isFullscreen = false
    @State private var isSidebarVisible = true
    @State private var isHoveringLeftEdge = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar (Windowed Mode)
            if isSidebarVisible && !isFullscreen {
                SidebarView(playlistManager: playlistManager, selectedChannel: $selectedChannel)
                    .frame(width: 250)
            }
            
            // Player Container
            ZStack(alignment: .leading) {
                Color.black.edgesIgnoringSafeArea(.all)
                
                PlayerView(player: playerViewModel.player)
                    .edgesIgnoringSafeArea(.all)
                    .onHover { hovering in
                        if hovering {
                            playerViewModel.userInteracted()
                        }
                    }
                    .onTapGesture(count: 2) {
                        toggleFullscreen()
                    }
                
                // Sidebar Overlay (Fullscreen Mode)
                if isFullscreen && isHoveringLeftEdge {
                    HStack(spacing: 0) {
                        SidebarView(playlistManager: playlistManager, selectedChannel: $selectedChannel)
                            .frame(width: 250)
                            .background(.regularMaterial)
                            .transition(.move(edge: .leading))
                            .onHover { hovering in
                                isHoveringLeftEdge = hovering
                            }
                        
                        // Invisible strip to detect mouse exit from sidebar
                        Color.clear
                            .frame(width: 20)
                            .contentShape(Rectangle())
                            .onHover { hovering in
                                if hovering {
                                    isHoveringLeftEdge = false
                                }
                            }
                        
                        Spacer()
                    }
                    .zIndex(2)
                }
                
                // Controls Overlay
                if playerViewModel.showControls {
                    VideoControlsView(viewModel: playerViewModel)
                        .transition(.opacity)
                        .zIndex(3)
                }
                
                // Left Edge Detection (Fullscreen only)
                if isFullscreen {
                    Color.clear
                        .frame(width: 20)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering {
                                isHoveringLeftEdge = true
                                playerViewModel.userInteracted()
                            }
                        }
                        .zIndex(4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onContinuousHover { phase in
                switch phase {
                case .active(_):
                    playerViewModel.userInteracted()
                case .ended:
                    break
                }
            }
        }
        .onChange(of: selectedChannel) { newChannel in
            if let channel = newChannel {
                playerViewModel.loadChannel(channel)
            }
        }
    }
    
    private func toggleFullscreen() {
        isFullscreen.toggle()
        
        // Reset sidebar states when entering/exiting fullscreen
        if isFullscreen {
            // Entering fullscreen: hide sidebar and hover state
            isSidebarVisible = false
            isHoveringLeftEdge = false
        } else {
            // Exiting fullscreen: restore sidebar
            isSidebarVisible = true
            isHoveringLeftEdge = false
        }
        
        // Show controls briefly when toggling
        playerViewModel.userInteracted()
        
        if let window = NSApp.windows.first(where: { $0.isKeyWindow }) {
            window.toggleFullScreen(nil)
        }
    }
}
