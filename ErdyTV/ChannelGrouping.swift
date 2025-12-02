import Foundation

enum ChannelItem: Identifiable, Hashable {
    case channel(Channel)
    case group(id: String, name: String, items: [ChannelItem])
    
    var id: String {
        switch self {
        case .channel(let channel):
            return channel.id.uuidString
        case .group(let id, _, _):
            return id
        }
    }
    
    var name: String {
        switch self {
        case .channel(let channel):
            return channel.name
        case .group(_, let name, _):
            return name
        }
    }
}

class ChannelGrouper {
    static func groupChannels(_ channels: [Channel]) -> [ChannelItem] {
        if channels.count < 3 {
            return channels.map { .channel($0) }
        }
        
        var items: [ChannelItem] = []
        let sortedChannels = channels.sorted { $0.name < $1.name }
        
        // Regex patterns to identify series
        // 1. "Name S01E01" -> Group: "Name"
        // 2. "Name E01" -> Group: "Name"
        let seriesPatterns = [
            try! NSRegularExpression(pattern: "^(.*?)\\s+S(\\d+)", options: .caseInsensitive),
            try! NSRegularExpression(pattern: "^(.*?)\\s+E(\\d+)", options: .caseInsensitive)
        ]
        
        var i = 0
        while i < sortedChannels.count {
            let current = sortedChannels[i]
            var seriesName: String? = nil
            
            // Try to match a series pattern
            for pattern in seriesPatterns {
                let range = NSRange(location: 0, length: current.name.utf16.count)
                if let match = pattern.firstMatch(in: current.name, options: [], range: range) {
                    if let range1 = Range(match.range(at: 1), in: current.name) {
                        seriesName = String(current.name[range1]).trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    }
                }
            }
            
            // Fallback: Common Prefix Logic
            if seriesName == nil && i + 1 < sortedChannels.count {
                let next = sortedChannels[i + 1]
                if let prefix = commonPrefix(current.name, next.name), prefix.count > 5 {
                    seriesName = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "-_:|"))
                }
            }
            
            if let groupName = seriesName {
                var groupChannels: [Channel] = [current]
                var j = i + 1
                while j < sortedChannels.count {
                    let next = sortedChannels[j]
                    if next.name.starts(with: groupName) {
                        groupChannels.append(next)
                        j += 1
                    } else {
                        break
                    }
                }
                
                if groupChannels.count >= 3 {
                    // We found a series group. Now check for seasons within this group.
                    let groupItems = groupSeasons(groupChannels, seriesName: groupName)
                    items.append(.group(id: "group_\(groupName)", name: groupName, items: groupItems))
                    i = j
                    continue
                }
            }
            
            items.append(.channel(current))
            i += 1
        }
        
        return items
    }
    
    private static func groupSeasons(_ channels: [Channel], seriesName: String) -> [ChannelItem] {
        // Regex to extract season number: "S01" or "Season 1"
        let seasonPattern = try! NSRegularExpression(pattern: "S(\\d+)|Season\\s*(\\d+)", options: .caseInsensitive)
        
        var seasonMap: [String: [Channel]] = [:]
        var otherChannels: [Channel] = []
        
        for channel in channels {
            let range = NSRange(location: 0, length: channel.name.utf16.count)
            if let match = seasonPattern.firstMatch(in: channel.name, options: [], range: range) {
                var seasonNum: String?
                if match.range(at: 1).location != NSNotFound, let r = Range(match.range(at: 1), in: channel.name) {
                    seasonNum = String(channel.name[r])
                } else if match.range(at: 2).location != NSNotFound, let r = Range(match.range(at: 2), in: channel.name) {
                    seasonNum = String(channel.name[r])
                }
                
                if let num = seasonNum {
                    let key = "Season \(Int(num) ?? 0)" // Normalize "01" to "1"
                    seasonMap[key, default: []].append(channel)
                    continue
                }
            }
            otherChannels.append(channel)
        }
        
        var items: [ChannelItem] = []
        
        // Add Season groups
        let sortedSeasons = seasonMap.keys.sorted {
            let n1 = Int($0.components(separatedBy: " ").last ?? "0") ?? 0
            let n2 = Int($1.components(separatedBy: " ").last ?? "0") ?? 0
            return n1 < n2
        }
        
        for season in sortedSeasons {
            if let seasonChannels = seasonMap[season] {
                let seasonId = "group_\(seriesName)_\(season)"
                items.append(.group(id: seasonId, name: season, items: seasonChannels.map { .channel($0) }))
            }
        }
        
        // Add remaining channels
        items.append(contentsOf: otherChannels.map { .channel($0) })
        
        return items
    }
    
    private static func commonPrefix(_ str1: String, _ str2: String) -> String? {
        let c1 = Array(str1)
        let c2 = Array(str2)
        var prefix = ""
        
        for (i, char) in c1.enumerated() {
            if i < c2.count && c2[i] == char {
                prefix.append(char)
            } else {
                break
            }
        }
        
        if prefix.count > 0 {
            if let last = prefix.last, last.isNumber {
                while let last = prefix.last, last.isNumber {
                    prefix.removeLast()
                }
            }
        }
        
        return prefix.isEmpty ? nil : prefix
    }
}
