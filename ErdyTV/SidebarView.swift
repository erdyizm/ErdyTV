import SwiftUI

struct SidebarView: View {
    @ObservedObject var playlistManager: PlaylistManager
    @Binding var selectedChannel: Channel?
    @Binding var expandedCategories: Set<UUID>
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @AppStorage("showChannelIcons") private var showChannelIcons = true

    var body: some View {
        ZStack {
            List(selection: $selectedChannel) {
                ForEach(filteredCategories) { category in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedCategories.contains(category.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedCategories.insert(category.id)
                                } else {
                                    expandedCategories.remove(category.id)
                                }
                            }
                        )
                    ) {
                        ForEach(category.channels) { channel in
                            NavigationLink(value: channel) {
                                HStack {
                                    if showChannelIcons {
                                        if let logo = channel.logoURL {
                                            AsyncImageView(url: logo)
                                                .frame(width: 30, height: 30)
                                                .cornerRadius(4)
                                        } else {
                                            Image(systemName: "tv")
                                                .frame(width: 30, height: 30)
                                        }
                                    }
                                    
                                    Text(channel.name)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(selectedChannel?.id == channel.id ? Color.accentColor.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        Text(category.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            if playlistManager.isLoading {
                Color(nsColor: .windowBackgroundColor)
                    .opacity(0.8)
                    .ignoresSafeArea()
                
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading Channels...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
        }
        .searchable(text: $searchText, placement: .sidebar)
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            CategoryFilterView(playlistManager: playlistManager)
        }
        .onChange(of: selectedChannel) { newChannel in
            // Auto-expand the category containing the selected channel
            if let channel = newChannel,
               let category = playlistManager.categories.first(where: { cat in
                   cat.channels.contains(where: { $0.id == channel.id })
               }) {
                expandedCategories.insert(category.id)
            }
        }
    }
    
    var filteredCategories: [Category] {
        var cats = playlistManager.categories
        
        // Filter by visible categories
        cats = cats.filter { playlistManager.visibleCategories.contains($0.name) }
        
        // Filter by search text
        if searchText.count >= 3 {
            cats = cats.map { category in
                let filteredChannels = category.channels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                return Category(id: category.id, name: category.name, channels: filteredChannels)
            }.filter { !$0.channels.isEmpty }
        }
        
        return cats
    }
}

struct CategoryFilterView: View {
    @ObservedObject var playlistManager: PlaylistManager
    @Environment(\.dismiss) var dismiss
    @State private var isEditMode = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(playlistManager.categories) { category in
                    HStack {
                        if isEditMode {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                        }
                        Toggle(category.name, isOn: Binding(
                            get: { playlistManager.visibleCategories.contains(category.name) },
                            set: { _ in playlistManager.toggleCategoryVisibility(category.name) }
                        ))
                    }
                }
                .onMove { source, destination in
                    playlistManager.moveCategory(from: source, to: destination)
                }
            }
            .navigationTitle("Manage Categories")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(isEditMode ? "Done Editing" : "Reorder") {
                        isEditMode.toggle()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 350, minHeight: 450)
    }
}
