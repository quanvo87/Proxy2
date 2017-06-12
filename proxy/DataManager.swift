//
//  DataManager.swift
//  proxy
//
//  Created by Quan Vo on 6/11/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

class DataManager {
    static let shared = DataManager()

    lazy var uid = ""
    lazy var cache = NSCache<AnyObject, AnyObject>()

    private init() {}
}
