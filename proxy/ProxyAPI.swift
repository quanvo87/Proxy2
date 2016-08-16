//
//  ProxyAPI.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class ProxyAPI: NSObject {
    
    let kinveyManager: KinveyManager
    let coreDataManager: CoreDataManager
    
    class var sharedInstance: ProxyAPI {
        struct Singleton {
            static let instance = ProxyAPI()
        }
        return Singleton.instance
    }
    
    override init() {
        kinveyManager = KinveyManager()
        coreDataManager = CoreDataManager()
        super.init()
    }
    
    func getProxies() -> [Proxy] {
        return coreDataManager.getProxies()
    }
    
    func createProxy(name: String, nickname: String) {
        kinveyManager.createProxy(name, nickname: nickname)
    }
}