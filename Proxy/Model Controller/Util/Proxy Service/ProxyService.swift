struct ProxyService {
    static let iconNames: [String] = {
        return ProxyService.makeIconNames()
    }()

    static let words: (adjectives: [String], nouns: [String]) = {
        return (adjectives: ProxyService.makeAdjectives(), nouns: ProxyService.makeNouns())
    }()

    static func makeRandomIconName(iconNames: [String] = ProxyService.iconNames) -> String {
        guard let name = iconNames[safe: iconNames.count.random] else {
            return ""
        }
        return name
    }

    static func makeRandomProxyName(adjectives: [String] = ProxyService.words.adjectives, nouns: [String] = ProxyService.words.nouns, numberRange: Int = 9) -> String {
        guard
            let adjective = adjectives[safe: adjectives.count.random]?.lowercased().capitalized,
            let noun = nouns[safe: nouns.count.random]?.lowercased().capitalized else {
                return ""
        }
        let number = numberRange.random + 1
        return adjective + noun + String(number)
    }
}
