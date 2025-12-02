import AVKit
import Combine
import SwiftUI
import VLC

class PlayerViewModel: NSObject, ObservableObject, VLCMediaPlayerDelegate {
    @Published var player: VLCMediaPlayer = VLCMediaPlayer()
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLive = false
    @Published var showControls = false
    @Published var isBuffering = false
    @Published var volume: Float = 1.0
    
    let fullscreenRequested = PassthroughSubject<Void, Never>()
    
    private var hideControlsTimer: Timer?
    private let kVolumeKey = "player_volume"
    
    private var expectedIsLive = false
    
    override init() {
        super.init()
        player.delegate = self
        
        // Load saved volume
        if UserDefaults.standard.object(forKey: kVolumeKey) != nil {
            volume = UserDefaults.standard.float(forKey: kVolumeKey)
        }
    }
    
    func loadChannel(_ channel: Channel) {
        player.stop()
        
        expectedIsLive = channel.isLive
        
        let media = VLCMedia(url: channel.streamURL)
        
        // Add options to fix freezing on live streams
        // network-caching: Increase buffer to 1.5s (or user setting)
        // clock-jitter: Disable clock jitter correction
        // clock-synchro: Disable clock synchronization
        
        let caching = UserDefaults.standard.integer(forKey: "networkCaching")
        let networkCaching = caching > 0 ? caching : 1500 // Default to 1500 if not set
        
        media.addOptions([
            "network-caching": networkCaching,
            "clock-jitter": 0,
            "clock-synchro": 0
        ])
        
        player.media = media
        player.play()
        
        // Apply volume
        player.audio?.volume = Int32(volume * 100)
        
        isLive = channel.isLive
        showControls = true
        resetHideControlsTimer()
    }
    
    func togglePlayPause() {
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        resetHideControlsTimer()
    }
    
    func seek(to time: Double) {
        if isLive { return }
        // VLC time is Int32 milliseconds
        let timeInInt = Int32(time * 1000)
        player.time = VLCTime(int: timeInInt)
        resetHideControlsTimer()
    }
    
    func skipForward() {
        if isLive { return }
        let current = player.time.intValue
        let newTime = current + 30000 // +30 seconds
        player.time = VLCTime(int: newTime)
        resetHideControlsTimer()
    }
    
    func skipBackward() {
        if isLive { return }
        let current = player.time.intValue
        let newTime = current - 30000 // -30 seconds
        player.time = VLCTime(int: newTime)
        resetHideControlsTimer()
    }
    
    func userInteracted() {
        showControls = true
        resetHideControlsTimer()
    }
    
    func requestFullscreen() {
        fullscreenRequested.send()
        userInteracted()
    }
    
    func setVolume(_ value: Float) {
        volume = value
        player.audio?.volume = Int32(value * 100)
        UserDefaults.standard.set(value, forKey: kVolumeKey)
        userInteracted()
    }
    
    private func resetHideControlsTimer() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            withAnimation {
                self?.showControls = false
            }
        }
    }
    
    // MARK: - VLCMediaPlayerDelegate
    
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        DispatchQueue.main.async {
            self.isPlaying = self.player.isPlaying
            
            // Update buffering state
            self.isBuffering = self.player.state == .opening || self.player.state == .buffering
            
            if self.player.state == .playing {
                // Check if live based on length
                // VLC length is -1 or 0 for live streams often, or very large
                let length = self.player.media?.length.intValue ?? 0
                if length <= 0 {
                    // Only switch to live if we EXPECT it to be live
                    // Otherwise, assume it's VOD and duration just hasn't loaded yet
                    if self.expectedIsLive {
                        self.isLive = true
                        self.duration = 0
                    }
                } else {
                    self.isLive = false
                    self.duration = Double(length) / 1000.0
                }
            }
        }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        DispatchQueue.main.async {
            self.currentTime = Double(self.player.time.intValue) / 1000.0
            // If time is changing, we are definitely playing
            if self.isBuffering {
                self.isBuffering = false
            }
        }
    }
}
