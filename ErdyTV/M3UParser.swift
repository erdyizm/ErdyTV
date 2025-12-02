import Foundation

struct Channel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let logoURL: URL?
    let streamURL: URL
    let group: String
    
    var isLive: Bool {
        // Check for common video extensions
        let ext = streamURL.pathExtension.lowercased()
        if ["mp4", "mkv", "avi", "mov", "flv", "wmv"].contains(ext) {
            return false
        }
        
        // Check for Series/Episode patterns in the name
        // e.g. "S01E01", "E01", "Season 1"
        let patterns = [
            "S\\d+E\\d+",      // S01E01
            "\\sE\\d+",        // E01
            "Season\\s*\\d+"   // Season 1
        ]
        
        for pattern in patterns {
            if name.range(of: pattern, options: .regularExpression) != nil {
                return false
            }
        }
        
        return true
    }
}

struct Category: Identifiable, Hashable {
    let id: UUID
    let name: String
    var channels: [Channel]
    var groupedChannels: [ChannelItem]? // Cache for grouped channels
    
    init(id: UUID = UUID(), name: String, channels: [Channel], groupedChannels: [ChannelItem]? = nil) {
        self.id = id
        self.name = name
        self.channels = channels
        self.groupedChannels = groupedChannels
    }
}

class M3UParser {
    static func parse(content: String) -> [Category] {
        var categories: [String: [Channel]] = [:]
        var currentGroup = "Uncategorized"
        var currentLogo: URL?
        var currentName: String?
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            if trimmed.hasPrefix("#EXTINF") {
                // Parse metadata
                // Example: #EXTINF:-1 tvg-logo="http://..." group-title="News",Channel Name
                
                // Extract group-title
                if let groupRange = trimmed.range(of: "group-title=\"") {
                    let substring = trimmed[groupRange.upperBound...]
                    if let endQuote = substring.firstIndex(of: "\"") {
                        currentGroup = String(substring[..<endQuote])
                    }
                } else {
                    currentGroup = "Uncategorized"
                }
                
                // Extract logo
                if let logoRange = trimmed.range(of: "tvg-logo=\"") {
                    let substring = trimmed[logoRange.upperBound...]
                    if let endQuote = substring.firstIndex(of: "\"") {
                        let urlString = String(substring[..<endQuote])
                        currentLogo = URL(string: urlString)
                    }
                } else {
                    currentLogo = nil
                }
                
                // Extract name (after the last comma)
                if let commaIndex = trimmed.lastIndex(of: ",") {
                    currentName = String(trimmed[commaIndex...].dropFirst()).trimmingCharacters(in: .whitespaces)
                } else {
                    currentName = "Unknown Channel"
                }
                
            } else if !trimmed.hasPrefix("#") {
                // This should be the URL
                if let url = URL(string: trimmed), let name = currentName {
                    let channel = Channel(name: name, logoURL: currentLogo, streamURL: url, group: currentGroup)
                    categories[currentGroup, default: []].append(channel)
                }
                
                // Reset for next entry
                currentName = nil
                currentLogo = nil
                currentGroup = "Uncategorized"
            }
        }
        
        return categories.map { Category(name: $0.key, channels: $0.value) }
            .sorted { $0.name < $1.name }
    }
}
