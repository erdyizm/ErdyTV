import SwiftUI

struct OnboardingView: View {
    @ObservedObject var playlistManager: PlaylistManager
    @State private var urlString = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            
            Text("Welcome to ErdyTV")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Please enter your IPTV M3U Playlist URL to get started.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            TextField("https://example.com/playlist.m3u", text: $urlString)
                .textFieldStyle(.roundedBorder)
                .frame(width: 400)
            
            Button("Load Playlist") {
                if let url = URL(string: urlString), url.scheme != nil, url.host != nil {
                    playlistManager.savedURL = url
                    playlistManager.loadPlaylist()
                } else {
                    showError = true
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .alert("Invalid URL", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a valid URL starting with http:// or https://")
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}
