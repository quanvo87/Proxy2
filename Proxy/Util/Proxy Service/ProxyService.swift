struct ProxyService {
    static let iconNames: [String] = {
        return ProxyService.makeIconNames()
    }()

    static let words: (adjectives: [String], nouns: [String]) = {
        return (adjectives: ProxyService.makeAdjectives(), nouns: ProxyService.makeNouns())
    }()
}
