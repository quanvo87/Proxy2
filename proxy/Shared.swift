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
    lazy var nouns = [String]()
    lazy var iconNames = [String]()

    lazy var proxyInfoLoaded = DispatchGroup()

    private init() {}
}
