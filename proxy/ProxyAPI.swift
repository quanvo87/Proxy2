//
//  ProxyAPI.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import CoreData

class ProxyAPI: NSObject {
    
    let kinveyManager: KinveyManager
    let coreDataManager: CoreDataManager
    let context: NSManagedObjectContext
    
    class var sharedInstance: ProxyAPI {
        struct Singleton {
            static let instance = ProxyAPI()
        }
        return Singleton.instance
    }
    
    override init() {
        kinveyManager = KinveyManager()
        coreDataManager = CoreDataManager()
        context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        super.init()
    }
    
    func getProxies() -> [Proxy] {
        return coreDataManager.getProxies()
    }
    
    func createProxy() {
        kinveyManager.createProxy()
    }
    
    func saveLocal() {
        coreDataManager.saveContext()
    }
    
    func deleteProxyWithName(name: String) {
        kinveyManager.deleteProxyWithName(name)
    }
    
    func deleteProxyLocal(proxy: Proxy) {
        coreDataManager.deleteProxy(proxy)
    }
}