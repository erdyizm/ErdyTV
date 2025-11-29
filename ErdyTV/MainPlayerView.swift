import SwiftUI
import AppKit

struct MainPlayerView: View {
    @ObservedObject var playlistManager: PlaylistManager
    @StateObject private var playerViewModel = PlayerViewModel()
    @State private var selectedChannel: Channel?
    @State private var isFullscreen = false
    @State private var isHoveringLeftEdge = false
    @State private var expandedCategories: Set<UUID> = []
    
    // Custom Sidebar State
    @State private var sidebarWidth: CGFloat = 250
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar (Windowed Mode)
            if !isFullscreen {
                SidebarView(playlistManager: playlistManager, selectedChannel: $selectedChannel, expandedCategories: $expandedCategories)
                    .frame(width: max(200, min(400, sidebarWidth + dragOffset)))
                
                // Resize Handle
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1)
                    
                    // Hit area for easier grabbing
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 10)
                        .contentShape(Rectangle())
                }
                .frame(width: 10) // Total width of the divider area
                .onHover { inside in
                    if inside {
                        NSCursor.resizeLeftRight.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            let newWidth = sidebarWidth + value.translation.width
                            sidebarWidth = max(200, min(400, newWidth))
                        }
                )
            }
            
            // Player Container
            PlayerContainerView(
                playlistManager: playlistManager,
                playerViewModel: playerViewModel,
                selectedChannel: $selectedChannel,
                expandedCategories: $expandedCategories,
                isFullscreen: $isFullscreen,
                isHoveringLeftEdge: $isHoveringLeftEdge
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: selectedChannel) { newChannel in
            if let channel = newChannel {
                playerViewModel.loadChannel(channel)
            }
        }
        .onReceive(playerViewModel.fullscreenRequested) { _ in
            toggleFullscreen()
        }
        .onChange(of: playerViewModel.showControls) { show in
            if isFullscreen {
                if show {
                    NSCursor.unhide()
                } else {
                    NSCursor.hide()
                }
            }
        }
        .onAppear {
            // Ensure we don't start in fullscreen
            if let window = NSApp.windows.first(where: { $0.isKeyWindow }),
               window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            isFullscreen = true
            isHoveringLeftEdge = false
            // Cursor handling is done in onChange(of: showControls)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            isFullscreen = false
            isHoveringLeftEdge = false
            NSCursor.unhide()
        }
        .navigationTitle(isFullscreen ? "" : (selectedChannel?.name ?? "ErdyTV"))
        .toolbar(isFullscreen ? .hidden : .visible, for: .windowToolbar)
    }
    
    private func toggleFullscreen() {
        // Show controls briefly when toggling
        playerViewModel.userInteracted()
        
        if let window = NSApp.windows.first(where: { $0.isKeyWindow }) {
            window.toggleFullScreen(nil)
        }
    }
}

struct PlayerContainerView: View {
    @ObservedObject var playlistManager: PlaylistManager
    @ObservedObject var playerViewModel: PlayerViewModel
    @Binding var selectedChannel: Channel?
    @Binding var expandedCategories: Set<UUID>
    @Binding var isFullscreen: Bool
    @Binding var isHoveringLeftEdge: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.black
                .edgesIgnoringSafeArea(isFullscreen ? .all : [])
            
            PlayerView(player: playerViewModel.player)
                .edgesIgnoringSafeArea(isFullscreen ? .all : [])
                .onHover { hovering in
                    if hovering {
                        playerViewModel.userInteracted()
                    }
                }
                .onTapGesture(count: 2) {
                    playerViewModel.requestFullscreen()
                }
            
            // Buffering Indicator
            if playerViewModel.isBuffering {
                ZStack {
                    Color.black.opacity(0.4)
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                .transition(.opacity)
                .zIndex(1)
            }
            
            // Sidebar Overlay (Fullscreen Mode)
            if isFullscreen && isHoveringLeftEdge {
                HStack(spacing: 0) {
                    SidebarView(playlistManager: playlistManager, selectedChannel: $selectedChannel, expandedCategories: $expandedCategories)
                        .frame(width: 250)
                        .background(.regularMaterial)
                        .transition(.move(edge: .leading))
                        .onHover { hovering in
                            isHoveringLeftEdge = hovering
                        }
                    
                    // Invisible strip to detect mouse exit from sidebar
                    Rectangle()
                        .fill(Color.clear)
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
                
                // Channel Name Overlay (Fullscreen)
                if isFullscreen, let channel = selectedChannel {
                    VStack {
                        HStack {
                            Text(channel.name)
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                                .padding(.leading, 20)
                                .padding(.top, 20)
                            Spacer()
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                    .zIndex(3)
                }
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
}
