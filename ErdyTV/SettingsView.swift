import SwiftUI

struct SettingsView: View {
    @ObservedObject var playlistManager: PlaylistManager
    @AppStorage("showChannelIcons") private var showChannelIcons = true
    @AppStorage("enableChannelGrouping") private var enableChannelGrouping = true
    @AppStorage("networkCaching") private var networkCaching = 1500
    
    var body: some View {
        TabView {
            Form {
                Section("General") {
                    Toggle("Show Channel Icons", isOn: $showChannelIcons)
                    Toggle("Enable Channel Grouping", isOn: $enableChannelGrouping)
                }
                
                Section("Playback") {
                    Picker("Buffering Duration", selection: $networkCaching) {
                        Text("300 ms (Standard)").tag(300)
                        Text("1000 ms (1 sec)").tag(1000)
                        Text("1500 ms (1.5 sec)").tag(1500)
                        Text("3000 ms (3 sec)").tag(3000)
                        Text("5000 ms (5 sec)").tag(5000)
                    }
                    .help("Higher values improve stability but increase delay.")
                }
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .padding()
            
            VStack {
                if playlistManager.blockedURLs.isEmpty {
                    Text("No blocked channels")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(Array(playlistManager.blockedURLs), id: \.self) { url in
                            HStack {
                                Text(url)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button {
                                    playlistManager.unblockChannel(url: url)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .tabItem {
                Label("Blocked Channels", systemImage: "hand.raised.fill")
            }
            .padding()
        }
        .frame(width: 450, height: 300)
    }
}

#Preview {
    SettingsView(playlistManager: PlaylistManager())
}
