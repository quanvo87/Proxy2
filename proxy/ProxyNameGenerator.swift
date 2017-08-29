// TODO: Delete this shit
struct ProxyNameGenerator {
    
    let numRange: UInt32 = 9
    var adjs = [String]()
    var nouns = [String]()
    
    func generateProxyName() -> String {
        let adjsCount = UInt32(adjs.count)
        let nounsCount = UInt32(nouns.count)
        let adj = adjs[Int(arc4random_uniform(adjsCount))].lowercased().capitalized
        let noun = nouns[Int(arc4random_uniform(nounsCount))].lowercased().capitalized
        let num = String(Int(arc4random_uniform(numRange)) + 1)
        return adj + noun + num
    }
}
