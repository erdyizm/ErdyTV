import Foundation

struct Channel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let logoURL: URL?
    let streamURL: URL
    let group: String
    
    var isLive: Bool {
        // Simple heuristic: .m3u8 usually implies HLS (could be live or VOD), 
        // but often IPTV providers use .ts or no extension for live.
        // For now, let's assume everything is live unless it ends in common video extensions.
        let ext = streamURL.pathExtension.lowercased()
        return !["mp4", "mkv", "avi", "mov"].contains(ext)
    }
}

struct Category: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var channels: [Channel]
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
