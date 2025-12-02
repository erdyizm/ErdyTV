import SwiftUI

struct SidebarView: View {
    @ObservedObject var playlistManager: PlaylistManager
    @Binding var selectedChannel: Channel?
    @Binding var expandedCategories: Set<UUID>
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var sortAscending = true
    @AppStorage("showChannelIcons") private var showChannelIcons = true
    @AppStorage("enableChannelGrouping") private var enableChannelGrouping = true
    
    // Group expansion state
    @State private var expandedGroups: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                
                Button {
                    withAnimation {
                        sortAscending.toggle()
                    }
                } label: {
                    Image(systemName: sortAscending ? "textformat.abc" : "textformat.abc.dottedunderline")
                        .help(sortAscending ? "Sort Z-A" : "Sort A-Z")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 4)
                
                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .help("Filter Categories")
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
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
                            ChannelListView(
                                items: itemsForCategory(category),
                                selectedChannel: $selectedChannel,
                                expandedGroups: $expandedGroups,
                                playlistManager: playlistManager,
                                showChannelIcons: showChannelIcons
                            )
                        } label: {
                            Text(category.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .listStyle(.sidebar)
                
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
        
        // Optimization: If no search and default sort (A-Z), return as is to use cached groups
        if searchText.isEmpty && sortAscending {
            return cats
        }
        
        // Filter by search text
        if searchText.count >= 2 {
            cats = cats.map { category in
                let filteredChannels = category.channels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                return Category(id: category.id, name: category.name, channels: filteredChannels)
            }.filter { !$0.channels.isEmpty }
        }
        
        // Sort channels within categories
        cats = cats.map { category in
            let sortedChannels = category.channels.sorted {
                if sortAscending {
                    return $0.name < $1.name
                } else {
                    return $0.name > $1.name
                }
            }
            return Category(id: category.id, name: category.name, channels: sortedChannels)
        }
        
        return cats
    }
    
    func itemsForCategory(_ category: Category) -> [ChannelItem] {
        if enableChannelGrouping {
            if let cached = category.groupedChannels {
                return cached
            } else {
                return ChannelGrouper.groupChannels(category.channels)
            }
        } else {
            return category.channels.map { ChannelItem.channel($0) }
        }
    }
}

struct ChannelListView: View {
    let items: [ChannelItem]
    @Binding var selectedChannel: Channel?
    @Binding var expandedGroups: Set<String>
    @ObservedObject var playlistManager: PlaylistManager
    let showChannelIcons: Bool
    
    var body: some View {
        ForEach(items) { item in
            switch item {
            case .channel(let channel):
                ChannelRow(channel: channel, selectedChannel: selectedChannel, showIcon: showChannelIcons)
                    .tag(channel)
                    .contextMenu {
                        Button {
                            selectedChannel = channel
                        } label: {
                            Label("Play", systemImage: "play.fill")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            playlistManager.blockChannel(channel)
                        } label: {
                            Label("Remove Channel", systemImage: "trash")
                        }
                    }
                
            case .group(let id, let name, let subItems):
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedGroups.contains(id) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedGroups.insert(id)
                            } else {
                                expandedGroups.remove(id)
                            }
                        }
                    )
                ) {
                    ChannelListView(
                        items: subItems,
                        selectedChannel: $selectedChannel,
                        expandedGroups: $expandedGroups,
                        playlistManager: playlistManager,
                        showChannelIcons: showChannelIcons
                    )
                } label: {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.secondary)
                        Text(name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(countChannels(in: subItems))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    func countChannels(in items: [ChannelItem]) -> Int {
        var count = 0
        for item in items {
            switch item {
            case .channel:
                count += 1
            case .group(_, _, let subItems):
                count += countChannels(in: subItems)
            }
        }
        return count
    }
}

struct ChannelRow: View {
    let channel: Channel
    let selectedChannel: Channel?
    let showIcon: Bool
    
    var body: some View {
        NavigationLink(value: channel) {
            HStack {
                if showIcon {
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
