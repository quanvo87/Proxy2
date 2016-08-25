//
//  ProxyNameGenerator.swift
//  proxy
//
//  Created by Quan Vo on 8/23/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct ProxyNameGenerator {
    
    private let endingNumberRange: UInt32 = 99
    private var _adjectives = [String]()
    private var _nouns = [String]()
    private var _wordBankLoaded = false
    
    var adjectives: [String] {
        get {
            return _adjectives
        }
        set (newValue) {
            _adjectives = newValue
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
    
    var wordBankLoaded: Bool {
        get {
            return _wordBankLoaded
        }
        set (newValue) {
            _wordBankLoaded = newValue
        }
    }
    
    func generateProxyName() -> String {
        let adjectivesCount = UInt32(_adjectives.count)
        let nounsCount = UInt32(_nouns.count)
        let randomAdjective = _adjectives[Int(arc4random_uniform(adjectivesCount))].lowercaseString
        let randomNoun = _nouns[Int(arc4random_uniform(nounsCount))].lowercaseString.capitalizedString
        let endingNumber = String(Int(arc4random_uniform(endingNumberRange)) + 1)
        return randomAdjective + randomNoun + endingNumber
    }
}