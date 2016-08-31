//
//  ProxyNameGenerator.swift
//  proxy
//
//  Created by Quan Vo on 8/23/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct ProxyNameGenerator {
    
    private let numRange: UInt32 = 99
    private var _adjs = [String]()
    private var _nouns = [String]()
    
    var adjs: [String] {
        get {
            return _adjs
        }
        set {
            _adjs = newValue
        }
    }
    
    var nouns: [String] {
        get {
            return _nouns
        }
        set {
            _nouns = newValue
        }
    }
    
    func generateProxyName() -> String {
        let adjsCount = UInt32(_adjs.count)
        let nounsCount = UInt32(_nouns.count)
        let adj = _adjs[Int(arc4random_uniform(adjsCount))].lowercaseString
        let noun = _nouns[Int(arc4random_uniform(nounsCount))].lowercaseString.capitalizedString
        let num = String(Int(arc4random_uniform(numRange)) + 1)
        return adj + noun + num
    }
}