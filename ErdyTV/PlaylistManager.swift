import Foundation
import Combine

class PlaylistManager: ObservableObject {
    @Published var categories: [Category] = []
    @Published var visibleCategories: Set<String> = []
    @Published var categoryOrder: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let kPlaylistURLKey = "iptv_playlist_url"
    private let kVisibleCategoriesKey = "visible_categories"
    private let kCategoryOrderKey = "category_order"
    
    init() {
        loadVisibleCategories()
        loadCategoryOrder()
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
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data, let content = String(data: data, encoding: .utf8) else {
                    self?.errorMessage = "Failed to read playlist data"
                    return
                }
                
                self?.categories = M3UParser.parse(content: content)
                
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
    
    func clearPlaylist() {
        savedURL = nil
        categories = []
    }
}
