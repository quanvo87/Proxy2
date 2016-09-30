//
//  ProxyNameGenerator.swift
//  proxy
//
//  Created by Quan Vo on 8/23/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct ProxyNameGenerator {
    
    let numRange: UInt32 = 10
    var adjs = [String]()
    var nouns = [String]()
    var isLoaded = false
    
    func generateProxyName() -> String {
        let adjsCount = UInt32(adjs.count)
        let nounsCount = UInt32(nouns.count)
        let adj = adjs[Int(arc4random_uniform(adjsCount))].lowercaseString
        let noun = nouns[Int(arc4random_uniform(nounsCount))].lowercaseString.capitalizedString
        let num = String(Int(arc4random_uniform(numRange)))
        return adj + noun + num
    }
}
