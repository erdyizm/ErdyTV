import SwiftUI

struct SettingsView: View {
    @AppStorage("showChannelIcons") private var showChannelIcons = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Show Channel Icons", isOn: $showChannelIcons)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}

#Preview {
    SettingsView()
}
