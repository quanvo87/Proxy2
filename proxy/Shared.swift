//
//  Shared.swift
//  proxy
//
//  Created by Quan Vo on 6/11/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class Shared {
    static let shared = Shared()

    lazy var cache = NSCache<AnyObject, AnyObject>()

    lazy var uid = ""
    lazy var isCreatingProxy = false

    lazy var adjectives = [String]()
    lazy var adjCount: UInt32 = {
        return UInt32(Shared.shared.adjectives.count)
    }()

    lazy var nouns = [String]()
    lazy var nounCount: UInt32 = {
        return UInt32(Shared.shared.nouns.count)
    }()

    lazy var iconNames = [String]()
    lazy var iconNameCount: UInt32 = {
        return UInt32(Shared.shared.iconNames.count)
    }()

    lazy var proxyInfoLoaded = DispatchGroup()
    var proxyInfoIsLoaded: Bool {
        return  Shared.shared.adjCount > 0 &&
                Shared.shared.nounCount > 0 &&
                Shared.shared.iconNameCount > 0
    }

    private init() {}
}
