import Foundation

enum ChannelItem: Identifiable, Hashable {
    case channel(Channel)
    case group(name: String, channels: [Channel])
    
    var id: String {
        switch self {
        case .channel(let channel):
            return channel.id.uuidString
        case .group(let name, _):
            return "group_\(name)"
        }
    }
    
    var name: String {
        switch self {
        case .channel(let channel):
            return channel.name
        case .group(let name, _):
            return name
        }
    }
}

class ChannelGrouper {
    static func groupChannels(_ channels: [Channel]) -> [ChannelItem] {
        if channels.count < 5 {
            return channels.map { .channel($0) }
        }
        
        var items: [ChannelItem] = []
        let sortedChannels = channels.sorted { $0.name < $1.name }
        
        // Regex patterns to identify series
        // 1. "Name S01E01" -> Group: "Name S01"
        // 2. "Name E01" -> Group: "Name"
        let patterns = [
            // Match "Name S01" part
            try! NSRegularExpression(pattern: "^(.*?)\\s+S(\\d+)", options: .caseInsensitive),
            // Match "Name E01" part (if no Season)
            try! NSRegularExpression(pattern: "^(.*?)\\s+E(\\d+)", options: .caseInsensitive)
        ]
        
        var i = 0
        while i < sortedChannels.count {
            let current = sortedChannels[i]
            var groupName: String? = nil
            
            // Try to match a pattern
            for pattern in patterns {
                let range = NSRange(location: 0, length: current.name.utf16.count)
                if let match = pattern.firstMatch(in: current.name, options: [], range: range) {
                    if let range1 = Range(match.range(at: 1), in: current.name) {
                        let namePart = String(current.name[range1])
                        
                        // If pattern 1 (Season), append Season number to group name
                        if pattern.pattern.contains("S(\\d+)") {
                            if let range2 = Range(match.range(at: 2), in: current.name) {
                                let seasonPart = String(current.name[range2])
                                groupName = "\(namePart) S\(seasonPart)"
                            }
                        } else {
                            groupName = namePart
                        }
                        break
                    }
                }
            }
            
            // If we found a potential group name, look ahead
            if let detectedGroup = groupName {
                var group: [Channel] = [current]
                var j = i + 1
                while j < sortedChannels.count {
                    let next = sortedChannels[j]
                    if next.name.starts(with: detectedGroup) {
                        group.append(next)
                        j += 1
                    } else {
                        break
                    }
                }
                
                if group.count >= 3 {
                    items.append(.group(name: detectedGroup.trimmingCharacters(in: .whitespacesAndNewlines), channels: group))
                    i = j
                    continue
                }
            }
            
            // Fallback: Common Prefix Logic (Relaxed)
            if i + 1 < sortedChannels.count {
                let next = sortedChannels[i + 1]
                if let prefix = commonPrefix(current.name, next.name), prefix.count > 5 {
                    // Check if this prefix is "significant" (e.g. ends with a separator or space)
                    // This prevents cutting off in the middle of a word like "Movie 1" vs "Movie 10" -> "Movie 1"
                    
                    var j = i + 1
                    var group: [Channel] = [current]
                    
                    while j < sortedChannels.count {
                        if sortedChannels[j].name.hasPrefix(prefix) {
                            group.append(sortedChannels[j])
                            j += 1
                        } else {
                            break
                        }
                    }
                    
                    if group.count >= 3 {
                        // Clean the name
                        let cleanName = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "-_:|"))
                        items.append(.group(name: cleanName, channels: group))
                        i = j
                        continue
                    }
                }
            }
            
            items.append(.channel(current))
            i += 1
        }
        
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
        
        // Backtrack to the last space or separator to avoid splitting numbers
        // e.g. "Show E0" -> "Show E" -> "Show "
        if prefix.count > 0 {
            // If the prefix ends with a digit, it might be the cause of the issue (E0 vs E1)
            if let last = prefix.last, last.isNumber {
                // Remove trailing digits
                while let last = prefix.last, last.isNumber {
                    prefix.removeLast()
                }
            }
        }
        
        return prefix.isEmpty ? nil : prefix
    }
}
