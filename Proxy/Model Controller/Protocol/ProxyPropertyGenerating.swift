protocol ProxyPropertyGenerating {
    var iconNames: [String] { get }
    var randomIconName: String { get }
    var randomProxyName: String { get }
}

struct ProxyPropertyGenerator: ProxyPropertyGenerating {
    let iconNames: [String] = {
        return ProxyPropertyGenerator.loadIconNames()
    }()

    var randomIconName: String {
        return iconNames[iconNames.count.random]
    }

    var randomProxyName: String {
        let adjective = words.adjectives[words.adjectives.count.random].lowercased().capitalized
        let noun = words.nouns[words.nouns.count.random].lowercased().capitalized
        let number = 9.random + 1
        return adjective + noun + String(number)
    }

    private let words: (adjectives: [String], nouns: [String]) = {
        return (adjectives: ProxyPropertyGenerator.loadAdjectives(),
                nouns: ProxyPropertyGenerator.loadNouns())
    }()
}

private extension Int {
    var random: Int {
        return Int(arc4random_uniform(UInt32(self)))
    }
}
