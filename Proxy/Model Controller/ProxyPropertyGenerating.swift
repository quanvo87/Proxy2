protocol ProxyPropertyGenerating {
    var iconNames: [String] { get }
    var randomIconName: String { get }
    var randomProxyName: String { get }
}

struct ProxyPropertyGenerator: ProxyPropertyGenerating {
    let iconNames = ProxyPropertyGenerator.loadIconNames()

    var randomIconName: String {
        return iconNames[iconNames.count.random]
    }

    var randomProxyName: String {
        let adjective = words.adjectives[words.adjectives.count.random].lowercased().capitalized
        let noun = words.nouns[words.nouns.count.random].lowercased().capitalized
        let number = 9.random + 1
        return adjective + noun + String(number)
    }

    private let words = (
        adjectives: ProxyPropertyGenerator.loadAdjectives(),
        nouns: ProxyPropertyGenerator.loadNouns()
    )
}
