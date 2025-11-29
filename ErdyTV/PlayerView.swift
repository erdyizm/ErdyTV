import SwiftUI
import VLC

struct PlayerView: NSViewRepresentable {
    let player: VLCMediaPlayer
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        view.autoresizingMask = [.width, .height]
        
        // VLC needs an NSView to draw into
        // We delay attachment slightly to ensure view is ready, or just set it
        player.drawable = view
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Ensure drawable is set if view updates (though makeNSView usually handles it)
        if player.drawable as? NSView != nsView {
            player.drawable = nsView
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(player: player)
    }
    
    class Coordinator {
        let player: VLCMediaPlayer
        
        init(player: VLCMediaPlayer) {
            self.player = player
        }
    }
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if coordinator.player.drawable as? NSView == nsView {
            coordinator.player.drawable = nil
        }
    }
}
