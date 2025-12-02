import SwiftUI

struct SettingsView: View {
    @ObservedObject var playlistManager: PlaylistManager
    @AppStorage("showChannelIcons") private var showChannelIcons = true
    @AppStorage("enableChannelGrouping") private var enableChannelGrouping = true
    
    var body: some View {
        TabView {
            Form {
                Section {
                    Toggle("Show Channel Icons", isOn: $showChannelIcons)
                    Toggle("Enable Channel Grouping", isOn: $enableChannelGrouping)
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
