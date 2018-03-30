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
        var adjective = ""
        var noun = ""
        while adjective == "" && noun == "" {
            adjective = words.adjectives[words.adjectives.count.random].lowercased().capitalized
            noun = words.nouns[words.nouns.count.random].lowercased().capitalized
        }
        let number = 1000.random
        let numberString = number == 0 ? "" : String(number)
        return adjective + noun + numberString
    }

    private let words = (
        adjectives: ProxyPropertyGenerator.loadAdjectives(),
        nouns: ProxyPropertyGenerator.loadNouns()
    )
}
