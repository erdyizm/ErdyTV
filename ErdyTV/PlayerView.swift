import SwiftUI
import VLC

struct PlayerView: NSViewRepresentable {
    let player: VLCMediaPlayer
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        // VLC needs an NSView to draw into
        player.drawable = view
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Ensure drawable is set if view updates (though makeNSView usually handles it)
        if player.drawable as? NSView != nsView {
            player.drawable = nsView
        }
    }
}
