//
//  ProxyNameGenerator.swift
//  proxy
//
//  Created by Quan Vo on 8/23/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct ProxyNameGenerator {
    
    private let _num: UInt32 = 99
    private var _adjs = [String]()
    private var _nouns = [String]()
    private var _loaded = false
    
    var adjs: [String] {
        get {
            return _adjs
        }
        set (newValue) {
            _adjs = newValue
        }
    }
    
    var nouns: [String] {
        get {
            return _nouns
        }
        set (newValue) {
            _nouns = newValue
        }
    }
    
    var loaded: Bool {
        get {
            return _loaded
        }
        set (newValue) {
            _loaded = newValue
        }
    }
    
    func generateProxyName() -> String {
        let adjsCount = UInt32(_adjs.count)
        let nounsCount = UInt32(_nouns.count)
        let adj = _adjs[Int(arc4random_uniform(adjsCount))].lowercaseString
        let noun = _nouns[Int(arc4random_uniform(nounsCount))].lowercaseString.capitalizedString
        let num = String(Int(arc4random_uniform(_num)) + 1)
        return adj + noun + num
    }
}