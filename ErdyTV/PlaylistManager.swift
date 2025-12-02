import Foundation
import Combine

class PlaylistManager: ObservableObject {
    @Published var categories: [Category] = []
    @Published var visibleCategories: Set<String> = []
    @Published var categoryOrder: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var blockedURLs: Set<String> = []
    
    private let kPlaylistURLKey = "iptv_playlist_url"
    private let kVisibleCategoriesKey = "visible_categories"
    private let kCategoryOrderKey = "category_order"
    private let kBlockedURLsKey = "blocked_urls"
    
    init() {
        loadVisibleCategories()
        loadCategoryOrder()
        loadBlockedURLs()
    }
    
    var savedURL: URL? {
        get {
            if let string = UserDefaults.standard.string(forKey: kPlaylistURLKey) {
                return URL(string: string)
            }
            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.absoluteString, forKey: kPlaylistURLKey)
        }
    }
    
    func loadPlaylist() {
        guard let url = savedURL else { return }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to read playlist data"
                }
                return
            }
            
            // Parse in background
            let allCategories = M3UParser.parse(content: content)
            
            // Filter out blocked channels and pre-compute groups
            let processedCategories = allCategories.map { category in
                let filteredChannels = category.channels.filter { channel in
                    !(self?.blockedURLs.contains(channel.streamURL.absoluteString) ?? false)
                }
                
                // Pre-compute groups
                let grouped = ChannelGrouper.groupChannels(filteredChannels)
                
                return Category(id: category.id, name: category.name, channels: filteredChannels, groupedChannels: grouped)
            }.filter { !$0.channels.isEmpty }
            
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.categories = processedCategories
                
                // Apply saved order to categories
                self?.applyOrder()
                
                // Initialize visible categories if empty
                if self?.visibleCategories.isEmpty == true {
                    self?.visibleCategories = Set(self?.categories.map { $0.name } ?? [])
                    self?.saveVisibleCategories()
                }
                
                // Initialize category order if empty
                if self?.categoryOrder.isEmpty == true {
                    self?.categoryOrder = self?.categories.map { $0.name } ?? []
                    self?.saveCategoryOrder()
                }
            }
        }.resume()
    }
    
    func blockChannel(_ channel: Channel) {
        blockedURLs.insert(channel.streamURL.absoluteString)
        saveBlockedURLs()
        
        // Remove from current list immediately
        categories = categories.map { category in
            let filteredChannels = category.channels.filter { $0.id != channel.id }
            return Category(id: category.id, name: category.name, channels: filteredChannels)
        }.filter { !$0.channels.isEmpty }
    }
    
    func saveBlockedURLs() {
        let array = Array(blockedURLs)
        UserDefaults.standard.set(array, forKey: kBlockedURLsKey)
    }
    
    func loadBlockedURLs() {
        if let array = UserDefaults.standard.array(forKey: kBlockedURLsKey) as? [String] {
            blockedURLs = Set(array)
        }
    }
    
    func applyOrder() {
        // Sort categories based on saved order
        categories.sort { cat1, cat2 in
            let index1 = categoryOrder.firstIndex(of: cat1.name) ?? Int.max
            let index2 = categoryOrder.firstIndex(of: cat2.name) ?? Int.max
            return index1 < index2
        }
    }
    
    func saveVisibleCategories() {
        let array = Array(visibleCategories)
        UserDefaults.standard.set(array, forKey: kVisibleCategoriesKey)
    }
    
    func loadVisibleCategories() {
        if let array = UserDefaults.standard.array(forKey: kVisibleCategoriesKey) as? [String] {
            visibleCategories = Set(array)
        }
    }
    
    func toggleCategoryVisibility(_ categoryName: String) {
        if visibleCategories.contains(categoryName) {
            visibleCategories.remove(categoryName)
        } else {
            visibleCategories.insert(categoryName)
        }
        saveVisibleCategories()
    }
    
    func saveCategoryOrder() {
        UserDefaults.standard.set(categoryOrder, forKey: kCategoryOrderKey)
    }
    
    func loadCategoryOrder() {
        if let array = UserDefaults.standard.array(forKey: kCategoryOrderKey) as? [String] {
            categoryOrder = array
        }
    }
    
    func moveCategory(from source: IndexSet, to destination: Int) {
        var updatedOrder = categoryOrder
        
        // Extract items to move
        var movedItems: [String] = []
        for index in source.sorted().reversed() {
            movedItems.insert(updatedOrder.remove(at: index), at: 0)
        }
        
        // Insert at destination
        let insertIndex = destination > source.first! ? destination - source.count : destination
        for (offset, item) in movedItems.enumerated() {
            updatedOrder.insert(item, at: insertIndex + offset)
        }
        
        categoryOrder = updatedOrder
        saveCategoryOrder()
        applyOrder()
    }
    
    func unblockChannel(url: String) {
        if blockedURLs.contains(url) {
            blockedURLs.remove(url)
            saveBlockedURLs()
            // Reload playlist to bring back the channel
            loadPlaylist()
        }
    }
    
    func clearPlaylist() {
        savedURL = nil
        categories = []
    }
}
