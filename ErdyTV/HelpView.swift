import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("ErdyTV Help")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                Group {
                    Text("Getting Started")
                        .font(.title2)
                        .bold()
                    
                    Text("1. Launch ErdyTV.")
                    Text("2. If no playlist is loaded, you will be prompted to select an M3U playlist file or enter a URL.")
                    Text("3. Once loaded, your channels will appear in the sidebar on the left.")
                    Text("4. Click on a channel to start playing.")
                }
                
                Divider()
                
                Group {
                    Text("Controls")
                        .font(.title2)
                        .bold()
                    
                    Text("• **Play/Pause**: Click the play/pause button in the control bar or press Space.")
                    Text("• **Volume**: Use the slider in the control bar to adjust volume.")
                    Text("• **Fullscreen**: Double-click the video area or click the fullscreen icon. Press Esc to exit.")
                    Text("• **Sidebar**: Drag the divider to resize the sidebar. In fullscreen, hover the left edge to see the channel list.")
                }
                
                Divider()
                
                Group {
                    Text("Troubleshooting")
                        .font(.title2)
                        .bold()
                    
                    Text("• **Black Screen**: If the screen stays black, try selecting another channel and then switching back.")
                    Text("• **No Audio**: Check your system volume and the app's volume slider.")
                    Text("• **Playlist Issues**: Ensure your M3U file is valid and accessible.")
                }
                
                Divider()
                
                Group {
                    Text("Customization")
                        .font(.title2)
                        .bold()
                    
                    Text("• **Search**: Use the search bar at the top of the sidebar to filter channels by name (requires at least 3 characters).")
                    Text("• **Manage Categories**: Click the filter icon (line with circles) in the sidebar toolbar to hide or reorder channel categories.")
                    Text("• **Channel Icons**: Go to **ErdyTV > Settings** (or press Cmd+,) to toggle channel logos on or off.")
                }
                
                Divider()
                
                Text("For further assistance, please visit our GitHub repository.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

#Preview {
    HelpView()
}
